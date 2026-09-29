import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/core/database/app_database.dart';
import 'package:expensetracker/models/audit_log.dart';
import 'package:expensetracker/features/audit/data/audit_log_repository.dart';
import 'package:expensetracker/services/audit_log_service.dart';

void main() {
  late AppDatabase db;
  late AuditLogRepository repo;
  late AuditLogService service;

  setUp(() {
    db = AppDatabase.openInMemory();
    repo = AuditLogRepository(db);
    service = AuditLogService(repo);
  });

  tearDown(() {
    db.close();
  });

  test('creates and retrieves audit log entry', () async {
    await service.logTransactionCreated(
      id: 'tx_101',
      type: 'EXPENSE',
      amount: 850.0,
      categoryName: 'Food & Dining',
      merchant: 'Zomato',
      accountName: 'HDFC',
    );

    final logs = await repo.getLogs();
    expect(logs.length, 1);
    expect(logs.first.entityId, 'tx_101');
    expect(logs.first.eventType, AuditEventType.create);
    expect(logs.first.severity, AuditSeverity.success);
    expect(logs.first.title, contains('Transaction Created'));
  });

  test('records update diffs between old and new state', () async {
    await service.logTransactionUpdated(
      id: 'tx_101',
      title: 'Zomato',
      oldValueDiff: 'Amount: ₹850.00\nCategory: Food',
      newValueDiff: 'Amount: ₹920.00\nCategory: Dining',
    );

    final logs = await repo.getLogs();
    expect(logs.length, 1);
    expect(logs.first.eventType, AuditEventType.update);
    expect(logs.first.oldValue, contains('₹850.00'));
    expect(logs.first.newValue, contains('₹920.00'));
  });

  test('records transaction deletion event', () async {
    await service.logTransactionDeleted(
      id: 'tx_101',
      title: 'Zomato',
      summary: '₹920.00 (Dining via HDFC)',
    );

    final logs = await repo.getLogs();
    expect(logs.length, 1);
    expect(logs.first.eventType, AuditEventType.delete);
    expect(logs.first.severity, AuditSeverity.warning);
  });

  test('records validation failure event', () async {
    await service.logValidationFailed(
      feature: 'Transaction',
      rule: 'INVALID_AMOUNT',
      message: 'Amount must be greater than zero',
    );

    final logs = await repo.getLogs();
    expect(logs.length, 1);
    expect(logs.first.eventType, AuditEventType.validation);
    expect(logs.first.result, AuditResult.failed);
    expect(logs.first.errorMessage, 'Amount must be greater than zero');
  });

  test('records application error event', () async {
    await service.logError(
      feature: 'Database',
      operation: 'Insert Transaction',
      error: 'Constraint failed',
    );

    final logs = await repo.getLogs();
    expect(logs.length, 1);
    expect(logs.first.eventType, AuditEventType.error);
    expect(logs.first.severity, AuditSeverity.error);
    expect(logs.first.result, AuditResult.failed);
  });

  test('searches logs by keyword query', () async {
    await service.logTransactionCreated(
      id: 'tx_1',
      type: 'EXPENSE',
      amount: 450.0,
      categoryName: 'Food',
      merchant: 'Swiggy',
      accountName: 'Cash',
    );
    await service.logTransactionCreated(
      id: 'tx_2',
      type: 'EXPENSE',
      amount: 1200.0,
      categoryName: 'Shopping',
      merchant: 'Amazon',
      accountName: 'Bank',
    );

    final swiggyLogs = await repo.getLogs(searchQuery: 'Swiggy');
    expect(swiggyLogs.length, 1);
    expect(swiggyLogs.first.entityId, 'tx_1');

    final amazonLogs = await repo.getLogs(searchQuery: 'Amazon');
    expect(amazonLogs.length, 1);
    expect(amazonLogs.first.entityId, 'tx_2');
  });

  test('filters logs by entity type and severity', () async {
    await service.logAccountCreated(
      id: 'acc_1',
      name: 'Axis Bank',
      type: 'Bank',
      startingBalance: 10000,
    );
    await service.logValidationFailed(
      feature: 'Account',
      rule: 'EMPTY_NAME',
      message: 'Name required',
    );

    final accountSuccessLogs = await repo.getLogs(
      entityTypeFilter: 'Account',
      severityFilter: AuditSeverity.success,
    );
    expect(accountSuccessLogs.length, 1);
    expect(accountSuccessLogs.first.entityId, 'acc_1');
  });

  test('retrieves complete history for a specific entity ID', () async {
    await service.logTransactionCreated(
      id: 'tx_99',
      type: 'EXPENSE',
      amount: 100,
      categoryName: 'Food',
      merchant: 'Cafe',
      accountName: 'Cash',
    );
    await service.logTransactionUpdated(
      id: 'tx_99',
      title: 'Cafe',
      oldValueDiff: 'Amount: ₹100.00',
      newValueDiff: 'Amount: ₹150.00',
    );

    final history = await repo.getEntityHistory('Transaction', 'tx_99');
    expect(history.length, 2);
    expect(history.first.eventType, AuditEventType.update);
    expect(history.last.eventType, AuditEventType.create);
  });
}
