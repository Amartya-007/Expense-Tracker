import 'package:expensetracker/services/sms_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes a debit bank SMS and extracts the expense', () {
    final result = SmsParserService.parseSms(
      'Rs.499.00 debited from your HDFC Bank account at Swiggy on 27-09-26.',
    );

    expect(result.isTransaction, isTrue);
    expect(result.isDebit, isTrue);
    expect(result.amount, 499);
    expect(result.merchant, 'Swiggy');
    expect(result.categorySuggestion, 'Food & Dining');
  });

  test('ignores OTP messages even when they contain a number', () {
    final result = SmsParserService.parseSms(
      'Your OTP is 123456. Do not share this verification code.',
    );

    expect(result.isTransaction, isFalse);
    expect(result.amount, 0);
  });
}
