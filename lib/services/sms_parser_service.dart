import 'package:expensetracker/models/transaction.dart';

class ParsedSmsResult {
  final bool isTransaction;
  final bool isDebit;
  final double amount;
  final String merchant;
  final String accountRef;
  final String categorySuggestion;
  final String rawSms;

  ParsedSmsResult({
    required this.isTransaction,
    required this.isDebit,
    required this.amount,
    required this.merchant,
    required this.accountRef,
    required this.categorySuggestion,
    required this.rawSms,
  });
}

class SmsParserService {
  static const List<String> _ignoreKeywords = [
    'otp',
    'verification code',
    'one time password',
    'do not share',
    'apply for',
    'pre-approved',
    'congratulations',
    'offer expires',
    'win up to',
  ];

  static ParsedSmsResult parseSms(String body) {
    final lower = body.toLowerCase();

    // Check if it's promotional/OTP
    for (final kw in _ignoreKeywords) {
      if (lower.contains(kw)) {
        return ParsedSmsResult(
          isTransaction: false,
          isDebit: true,
          amount: 0.0,
          merchant: '',
          accountRef: '',
          categorySuggestion: 'Other',
          rawSms: body,
        );
      }
    }

    bool isDebit = true;

    if (lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('salary') ||
        lower.contains('deposited')) {
      isDebit = false;
    } else if (lower.contains('debited') ||
        lower.contains('spent') ||
        lower.contains('sent') ||
        lower.contains('paid')) {
      isDebit = true;
    } else {
      // Not a recognized transaction SMS
      return ParsedSmsResult(
        isTransaction: false,
        isDebit: true,
        amount: 0.0,
        merchant: '',
        accountRef: '',
        categorySuggestion: 'Other',
        rawSms: body,
      );
    }

    // Extract amount: "Rs 486.00" or "Rs. 1,299" or "INR 500"
    double amount = 0.0;

    final amountReg = RegExp(
      r'(?:rs\.?|inr|inr\.)\s*([\d,]+(?:\.\d+)?)|(?:debited|credited|spent|paid)\s*(?:by|of)?\s*(?:rs\.?|inr)?\s*([\d,]+(?:\.\d+)?)',
    );

    final match = amountReg.firstMatch(lower);

    if (match != null) {
      final matchStr = (match.group(1) ?? match.group(2) ?? '').replaceAll(
        ',',
        '',
      );

      amount = double.tryParse(matchStr) ?? 0.0;
    }

    if (amount <= 0.0) {
      return ParsedSmsResult(
        isTransaction: false,
        isDebit: isDebit,
        amount: 0.0,
        merchant: '',
        accountRef: '',
        categorySuggestion: 'Other',
        rawSms: body,
      );
    }

    // Extract merchant
    String merchant = 'General Merchant';

    if (lower.contains('swiggy')) {
      merchant = 'Swiggy';
    } else if (lower.contains('zomato')) {
      merchant = 'Zomato';
    } else if (lower.contains('amazon')) {
      merchant = 'Amazon';
    } else if (lower.contains('flipkart')) {
      merchant = 'Flipkart';
    } else if (lower.contains('uber')) {
      merchant = 'Uber';
    } else if (lower.contains('ola')) {
      merchant = 'Ola';
    } else if (lower.contains('airtel')) {
      merchant = 'Airtel';
    } else if (lower.contains('jio')) {
      merchant = 'Reliance Jio';
    } else if (lower.contains('electricity')) {
      merchant = 'Electricity Board';
    } else if (lower.contains('petrol') || lower.contains('fuel')) {
      merchant = 'Fuel Station';
    } else if (lower.contains('netflix')) {
      merchant = 'Netflix';
    } else {
      final merchantReg = RegExp(
        r'(?:at|to|vpa)\s+([a-zA-Z0-9\s&]+?)(?=\s+on|\s+ref|\s+via|\.|$)',
      );

      final mMatch = merchantReg.firstMatch(lower);

      if (mMatch != null && mMatch.group(1)!.trim().isNotEmpty) {
        final rawM = mMatch.group(1)!.trim();

        if (rawM.length < 25) {
          merchant = rawM
              .split(' ')
              .map(
                (w) => w.isNotEmpty
                    ? '${w[0].toUpperCase()}${w.substring(1)}'
                    : '',
              )
              .join(' ');
        }
      }
    }

    // Extract Account reference
    String accountRef = '';

    if (lower.contains('bank of india') || lower.contains('boi')) {
      accountRef = 'BOI Account';
    } else if (lower.contains('axis bank') ||
        lower.contains('axisbank') ||
        lower.contains('axis')) {
      accountRef = 'Axis Bank Account';
    } else if (lower.contains('sbi') || lower.contains('state bank of india')) {
      accountRef = 'SBI Account';
    } else if (lower.contains('icici bank') || lower.contains('icicibank')) {
      accountRef = 'ICICI Account';
    } else if (lower.contains('paytm')) {
      accountRef = 'Paytm Wallet';
    } else if (lower.contains('hdfc bank') || lower.contains('hdfcbank')) {
      accountRef = 'HDFC Savings';
    }

    // Category suggestion
    String category = 'Other';

    if (merchant.toLowerCase().contains('swiggy') ||
        merchant.toLowerCase().contains('zomato')) {
      category = 'Food & Dining';
    } else if (merchant.toLowerCase().contains('amazon') ||
        merchant.toLowerCase().contains('flipkart')) {
      category = 'Shopping';
    } else if (merchant.toLowerCase().contains('uber') ||
        merchant.toLowerCase().contains('ola')) {
      category = 'Transport';
    } else if (merchant.toLowerCase().contains('airtel') ||
        merchant.toLowerCase().contains('electricity')) {
      category = 'Bills & Utilities';
    } else if (!isDebit) {
      category = 'Salary';
    }

    return ParsedSmsResult(
      isTransaction: true,
      isDebit: isDebit,
      amount: amount,
      merchant: merchant,
      accountRef: accountRef,
      categorySuggestion: category,
      rawSms: body,
    );
  }

  // Duplicate Check Helper
  static bool isLikelyDuplicate(
    ParsedSmsResult parsed,
    List<TransactionItem> existingTransactions, {
    DateTime? receivedAt,
  }) {
    if (!parsed.isTransaction) return false;

    final messageDate = receivedAt ?? DateTime.now();

    for (final t in existingTransactions) {
      if ((t.amount - parsed.amount).abs() < 1.0) {
        if (t.merchant.toLowerCase().contains(parsed.merchant.toLowerCase()) ||
            parsed.merchant.toLowerCase().contains(t.merchant.toLowerCase())) {
          if (t.date.day == messageDate.day &&
              t.date.month == messageDate.month &&
              t.date.year == messageDate.year) {
            return true;
          }
        }
      }
    }

    return false;
  }
}
