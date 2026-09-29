class Validators {
  /// Validates a financial monetary amount.
  /// Returns an error message string if invalid, or null if valid.
  static String? validateAmount(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null || !amount.isFinite) {
      return 'Please enter a valid numeric amount';
    }
    if (!allowZero && amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (allowZero && amount < 0) {
      return 'Amount cannot be negative';
    }
    return null;
  }

  /// Validates a required name/title string field.
  static String? validateRequiredName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  /// Validates that two selected account IDs are not identical for transfers.
  static String? validateTransferAccounts(String? fromAccountId, String? toAccountId) {
    if (fromAccountId == null || fromAccountId.isEmpty) {
      return 'Please select a source account';
    }
    if (toAccountId == null || toAccountId.isEmpty) {
      return 'Please select a destination account';
    }
    if (fromAccountId == toAccountId) {
      return 'Source and destination accounts must be different';
    }
    return null;
  }
}
