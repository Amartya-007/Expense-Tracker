import 'package:expensetracker/models/account.dart';
import 'package:expensetracker/core/database/app_database.dart';

class AccountRepository {
  final AppDatabase db;

  AccountRepository(this.db);

  static const _selectColumns = '''
    id, name, type, balance, starting_balance, account_number,
    credit_limit, due_date, min_due, low_balance_threshold,
    last_reconciled_at, last_reconciled_balance, color_hex, icon_name
  ''';

  Future<List<Account>> getAccounts() async {
    final rows = db.rawDb.select(
      'SELECT $_selectColumns FROM accounts ORDER BY name ASC, id ASC',
    );
    return rows.map(_mapRowToAccount).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final stmt = db.rawDb.prepare(
      'SELECT $_selectColumns FROM accounts WHERE id = ? LIMIT 1',
    );
    final rows = stmt.select([id]);
    stmt.dispose();
    if (rows.isEmpty) return null;
    return _mapRowToAccount(rows.first);
  }

  Future<void> replaceAccounts(List<Account> accounts) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      db.rawDb.execute('DELETE FROM accounts');
      final stmt = db.rawDb.prepare('''
        INSERT INTO accounts (
          id, name, type, balance, starting_balance, account_number,
          credit_limit, due_date, min_due, low_balance_threshold,
          last_reconciled_at, last_reconciled_balance, color_hex, icon_name
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      for (final acc in accounts) {
        stmt.execute([
          acc.id,
          acc.name,
          acc.type.name,
          acc.balance,
          acc.startingBalance,
          acc.accountNumber,
          acc.creditLimit,
          acc.dueDate,
          acc.minDue,
          acc.lowBalanceThreshold,
          acc.lastReconciledAt?.toIso8601String(),
          acc.lastReconciledBalance,
          acc.colorHex,
          acc.iconName,
        ]);
      }
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveAccounts(List<Account> accounts) => replaceAccounts(accounts);

  Account _mapRowToAccount(dynamic r) {
    AccountType type;
    final rawType = r['type'];
    if (rawType is String) {
      type = AccountType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => AccountType.bank,
      );
    } else if (rawType is int && rawType >= 0 && rawType < AccountType.values.length) {
      type = AccountType.values[rawType];
    } else {
      type = AccountType.bank;
    }

    return Account(
      id: r['id'] as String,
      name: r['name'] as String,
      type: type,
      balance: (r['balance'] as num).toDouble(),
      startingBalance: (r['starting_balance'] as num?)?.toDouble() ?? 0.0,
      accountNumber: r['account_number'] as String?,
      creditLimit: (r['credit_limit'] as num?)?.toDouble(),
      dueDate: r['due_date'] as String?,
      minDue: (r['min_due'] as num?)?.toDouble(),
      lowBalanceThreshold: (r['low_balance_threshold'] as num?)?.toDouble(),
      lastReconciledAt: r['last_reconciled_at'] == null
          ? null
          : DateTime.tryParse(r['last_reconciled_at'] as String),
      lastReconciledBalance: (r['last_reconciled_balance'] as num?)?.toDouble(),
      colorHex: (r['color_hex'] as int?) ?? 0xFF00B2E7,
      iconName: (r['icon_name'] as String?) ?? 'account_balance',
    );
  }
}
