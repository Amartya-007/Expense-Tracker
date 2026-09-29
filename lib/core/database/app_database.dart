import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  final Database _db;

  AppDatabase(this._db) {
    _initTables();
  }

  static Future<AppDatabase> open() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'rupeecommand.sqlite'));
    final db = sqlite3.open(file.path);
    return AppDatabase(db);
  }

  static AppDatabase openInMemory() {
    final db = sqlite3.openInMemory();
    return AppDatabase(db);
  }

  void close() {
    _db.dispose();
  }

  void _initTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT '',
        currency_symbol TEXT NOT NULL DEFAULT '₹',
        monthly_income_goal REAL NOT NULL DEFAULT 0.0,
        is_privacy_mode_enabled INTEGER NOT NULL DEFAULT 0,
        hide_balances INTEGER NOT NULL DEFAULT 0,
        is_dark_mode INTEGER NOT NULL DEFAULT 0,
        home_section_order TEXT NOT NULL DEFAULT '[]',
        is_onboarded INTEGER NOT NULL DEFAULT 0,
        onboarding_version INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        balance REAL NOT NULL,
        starting_balance REAL NOT NULL DEFAULT 0.0,
        account_number TEXT,
        credit_limit REAL,
        due_date TEXT,
        min_due REAL,
        low_balance_threshold REAL,
        last_reconciled_at TEXT,
        last_reconciled_balance REAL,
        color_hex INTEGER NOT NULL DEFAULT 4278235879,
        icon_name TEXT NOT NULL DEFAULT 'account_balance'
      );

      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        icon_code INTEGER NOT NULL DEFAULT 58780,
        color_hex INTEGER NOT NULL DEFAULT 4278235879,
        parent_category_id TEXT,
        subcategories TEXT NOT NULL DEFAULT '[]'
      );

      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        account_id TEXT NOT NULL,
        account_name TEXT NOT NULL,
        to_account_id TEXT,
        to_account_name TEXT,
        merchant TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        receipt_image_path TEXT,
        location TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        is_reviewed INTEGER NOT NULL DEFAULT 1,
        source TEXT NOT NULL DEFAULT 'manual',
        refunded_transaction_id TEXT,
        splits TEXT NOT NULL DEFAULT '[]'
      );

      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        period INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1
      );

      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        target_date TEXT NOT NULL,
        icon_name TEXT NOT NULL DEFAULT 'savings',
        note TEXT NOT NULL DEFAULT '',
        is_completed INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS recurring_bills (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        billing_cycle INTEGER NOT NULL DEFAULT 0,
        due_day INTEGER NOT NULL,
        next_due_date TEXT,
        installment_total INTEGER,
        installments_remaining INTEGER,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        account_id TEXT NOT NULL,
        account_name TEXT NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        is_paused INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS shared_expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        total_amount REAL NOT NULL,
        paid_by TEXT NOT NULL,
        participants TEXT NOT NULL DEFAULT '[]',
        splits TEXT NOT NULL DEFAULT '{}',
        settled_status TEXT NOT NULL DEFAULT '{}',
        date TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS review_queue (
        id TEXT PRIMARY KEY,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        suggested_category_id TEXT NOT NULL,
        suggested_category_name TEXT NOT NULL,
        suggested_account_id TEXT NOT NULL,
        suggested_account_name TEXT NOT NULL,
        source_notification TEXT NOT NULL,
        suggested_type INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS custom_tags (
        name TEXT PRIMARY KEY
      );

      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        event_type TEXT NOT NULL,
        severity TEXT NOT NULL,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        result TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        old_value TEXT,
        new_value TEXT,
        metadata TEXT NOT NULL DEFAULT '{}',
        screen TEXT,
        error_code TEXT,
        error_message TEXT,
        duration_ms INTEGER
      );

      CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_logs(timestamp);
      CREATE INDEX IF NOT EXISTS idx_audit_event_type ON audit_logs(event_type);
      CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);
      CREATE INDEX IF NOT EXISTS idx_audit_severity ON audit_logs(severity);
    ''');
  }

  Database get rawDb => _db;
}
