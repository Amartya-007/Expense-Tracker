import 'package:expensetracker/models/audit_log.dart';
import 'package:expensetracker/features/audit/data/audit_log_repository.dart';

class AuditLogService {
  final AuditLogRepository repository;

  AuditLogService(this.repository);

  static int _counter = 0;
  String _generateId() => 'aud_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  /// Safe logging method that NEVER throws or interrupts application execution.
  Future<void> logEvent(AuditLog log) async {
    try {
      await repository.insertLog(log);
    } catch (_) {
      // Fail-safe guard: Logging failure must never break financial operations.
    }
  }

  Future<void> logTransactionCreated({
    required String id,
    required String type,
    required double amount,
    required String categoryName,
    required String merchant,
    required String accountName,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.create,
        severity: AuditSeverity.success,
        action: 'TRANSACTION_CREATED',
        entityType: 'Transaction',
        entityId: id,
        result: AuditResult.success,
        title: 'Transaction Created ($type)',
        description: 'Recorded ${type.toLowerCase()} of ₹${amount.toStringAsFixed(2)} at $merchant ($categoryName via $accountName).',
        newValue: 'Amount: ₹${amount.toStringAsFixed(2)}\nType: $type\nCategory: $categoryName\nMerchant: $merchant\nAccount: $accountName',
        screen: screen ?? 'AddTransactionSheet',
      ),
    );
  }

  Future<void> logTransactionUpdated({
    required String id,
    required String title,
    required String oldValueDiff,
    required String newValueDiff,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.update,
        severity: AuditSeverity.success,
        action: 'TRANSACTION_UPDATED',
        entityType: 'Transaction',
        entityId: id,
        result: AuditResult.success,
        title: 'Transaction Updated',
        description: 'Modified transaction details for $title.',
        oldValue: oldValueDiff,
        newValue: newValueDiff,
        screen: screen ?? 'TransactionDetailScreen',
      ),
    );
  }

  Future<void> logTransactionDeleted({
    required String id,
    required String title,
    required String summary,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.delete,
        severity: AuditSeverity.warning,
        action: 'TRANSACTION_DELETED',
        entityType: 'Transaction',
        entityId: id,
        result: AuditResult.success,
        title: 'Transaction Deleted',
        description: 'Deleted transaction record: $title ($summary).',
        oldValue: summary,
        screen: screen ?? 'TransactionDetailScreen',
      ),
    );
  }

  Future<void> logTransactionRestored({
    required String id,
    required String title,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.restore,
        severity: AuditSeverity.success,
        action: 'TRANSACTION_RESTORED',
        entityType: 'Transaction',
        entityId: id,
        result: AuditResult.success,
        title: 'Transaction Restored',
        description: 'Restored deleted transaction: $title.',
        screen: screen ?? 'TransactionDetailScreen',
      ),
    );
  }

  Future<void> logTransactionSplit({
    required String id,
    required String title,
    required int splitCount,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.split,
        severity: AuditSeverity.success,
        action: 'TRANSACTION_SPLIT',
        entityType: 'Transaction',
        entityId: id,
        result: AuditResult.success,
        title: 'Transaction Split Across Categories',
        description: 'Split $title into $splitCount category portions.',
        screen: screen ?? 'SplitTransactionScreen',
      ),
    );
  }

  Future<void> logAccountCreated({
    required String id,
    required String name,
    required String type,
    required double startingBalance,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.create,
        severity: AuditSeverity.success,
        action: 'ACCOUNT_CREATED',
        entityType: 'Account',
        entityId: id,
        result: AuditResult.success,
        title: 'Account Created',
        description: 'Added new $type account "$name" with starting balance ₹${startingBalance.toStringAsFixed(2)}.',
        newValue: 'Name: $name\nType: $type\nBalance: ₹${startingBalance.toStringAsFixed(2)}',
        screen: screen ?? 'AccountsScreen',
      ),
    );
  }

  Future<void> logAccountDeleted({
    required String id,
    required String name,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.delete,
        severity: AuditSeverity.warning,
        action: 'ACCOUNT_DELETED',
        entityType: 'Account',
        entityId: id,
        result: AuditResult.success,
        title: 'Account Deleted',
        description: 'Permanently deleted account "$name".',
        screen: screen ?? 'AccountsScreen',
      ),
    );
  }

  Future<void> logValidationFailed({
    required String feature,
    required String rule,
    required String message,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.validation,
        severity: AuditSeverity.warning,
        action: 'VALIDATION_FAILED',
        entityType: feature,
        result: AuditResult.failed,
        title: 'Validation Failed',
        description: message,
        errorCode: rule,
        errorMessage: message,
        screen: screen,
      ),
    );
  }

  Future<void> logError({
    required String feature,
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.error,
        severity: AuditSeverity.error,
        action: 'APPLICATION_ERROR',
        entityType: feature,
        result: AuditResult.failed,
        title: 'Application Error ($operation)',
        description: error.toString(),
        errorMessage: error.toString(),
        metadata: stackTrace != null ? {'stackTrace': stackTrace.toString()} : {},
        screen: screen,
      ),
    );
  }

  Future<void> logDataImported({
    required String type,
    required int count,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.importData,
        severity: AuditSeverity.success,
        action: 'DATA_IMPORTED',
        entityType: 'Import',
        result: AuditResult.success,
        title: '$type Import Succeeded',
        description: 'Successfully imported $count $type records.',
        screen: screen ?? 'SettingsScreen',
      ),
    );
  }

  Future<void> logDataExported({
    required String type,
    String? screen,
  }) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.exportData,
        severity: AuditSeverity.info,
        action: 'DATA_EXPORTED',
        entityType: 'Export',
        result: AuditResult.success,
        title: '$type Exported',
        description: 'Exported local $type backup file.',
        screen: screen ?? 'SettingsScreen',
      ),
    );
  }

  Future<void> logDatabaseReset({String? screen}) async {
    await logEvent(
      AuditLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        eventType: AuditEventType.database,
        severity: AuditSeverity.critical,
        action: 'DATABASE_RESET',
        entityType: 'Database',
        result: AuditResult.success,
        title: 'Clean Slate Reset Executed',
        description: 'All local financial accounts, transactions, and settings were wiped clean.',
        screen: screen ?? 'SettingsScreen',
      ),
    );
  }
}
