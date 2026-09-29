import 'package:expensetracker/models/transaction.dart';

class VoiceParseResult {
  final TransactionType type;
  final double amount;
  final String merchant;
  final String categorySuggestion;
  final String note;

  VoiceParseResult({
    required this.type,
    required this.amount,
    required this.merchant,
    required this.categorySuggestion,
    required this.note,
  });
}

class VoiceParser {
  static VoiceParseResult parse(String text) {
    final lower = text.toLowerCase().trim();
    TransactionType type = TransactionType.expense;
    if (lower.contains('received') ||
        lower.contains('income') ||
        lower.contains('salary') ||
        lower.contains('got')) {
      type = TransactionType.income;
    } else if (lower.contains('transfer') || lower.contains('moved')) {
      type = TransactionType.transfer;
    }

    // Extract amount
    double amount = 0.0;
    final amountReg = RegExp(r'(\d+[\d,]*(\.\d+)?)');
    final match = amountReg.firstMatch(lower);
    if (match != null) {
      final clean = match.group(1)!.replaceAll(',', '');
      amount = double.tryParse(clean) ?? 0.0;
    }

    // Category suggestions & merchant
    String category = 'Other';
    String merchant = '';

    if (lower.contains('swiggy') || lower.contains('zomato') || lower.contains('dinner') || lower.contains('lunch') || lower.contains('food') || lower.contains('chai')) {
      category = 'Food & Dining';
      if (lower.contains('swiggy')) {
        merchant = 'Swiggy';
      } else if (lower.contains('zomato')) {
        merchant = 'Zomato';
      }
    } else if (lower.contains('uber') || lower.contains('ola') || lower.contains('cab') || lower.contains('auto') || lower.contains('fuel') || lower.contains('petrol')) {
      category = 'Transport';
      if (lower.contains('uber')) {
        merchant = 'Uber';
      } else if (lower.contains('ola')) {
        merchant = 'Ola';
      }
    } else if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('shopping')) {
      category = 'Shopping';
      if (lower.contains('amazon')) {
        merchant = 'Amazon';
      } else if (lower.contains('flipkart')) {
        merchant = 'Flipkart';
      }
    } else if (lower.contains('electricity') || lower.contains('wifi') || lower.contains('bill') || lower.contains('recharge')) {
      category = 'Bills';
    } else if (type == TransactionType.income && lower.contains('salary')) {
      category = 'Salary';
      merchant = 'Employer';
    }

    return VoiceParseResult(
      type: type,
      amount: amount,
      merchant: merchant.isNotEmpty ? merchant : 'General',
      categorySuggestion: category,
      note: text,
    );
  }
}
