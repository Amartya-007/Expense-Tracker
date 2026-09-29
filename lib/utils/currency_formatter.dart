import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String defaultSymbol = '₹';

  static String format(
    double amount, {
    String? symbol,
    bool isPrivacyMode = false,
    bool showSign = false,
  }) {
    final currencySymbol = symbol ?? defaultSymbol;
    if (isPrivacyMode) {
      return '$currencySymbol••••••';
    }

    final double absAmount = amount.abs();
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '$currencySymbol ',
      decimalDigits: absAmount % 1 == 0 ? 0 : 2,
    );

    String formatted = formatter.format(absAmount);

    if (showSign) {
      if (amount > 0) return '+$formatted';
      if (amount < 0) return '-$formatted';
    } else if (amount < 0) {
      return '-$formatted';
    }

    return formatted;
  }

  static String formatCompact(
    double amount, {
    String? symbol,
    bool isPrivacyMode = false,
  }) {
    final currencySymbol = symbol ?? defaultSymbol;
    if (isPrivacyMode) return '$currencySymbol••••';
    final absAmount = amount.abs();
    if (absAmount >= 10000000) {
      return '$currencySymbol${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (absAmount >= 100000) {
      return '$currencySymbol${(amount / 100000).toStringAsFixed(1)} L';
    } else if (absAmount >= 1000) {
      return '$currencySymbol${(amount / 1000).toStringAsFixed(1)} k';
    }
    return format(amount, symbol: currencySymbol);
  }
}
