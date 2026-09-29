import 'dart:convert';
import 'package:expensetracker/models/audit_log.dart';
import 'package:expensetracker/core/database/app_database.dart';

class AuditLogRepository {
  final AppDatabase db;

  AuditLogRepository(this.db);

  static const _selectColumns = '''
    id, timestamp, event_type, severity, action, entity_type, entity_id,
    result, title, description, old_value, new_value, metadata, screen,
    error_code, error_message, duration_ms
  ''';

  Future<void> insertLog(AuditLog log) async {
    final stmt = db.rawDb.prepare('''
      INSERT INTO audit_logs (
        id, timestamp, event_type, severity, action, entity_type, entity_id,
        result, title, description, old_value, new_value, metadata, screen,
        error_code, error_message, duration_ms
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      log.id,
      log.timestamp.toIso8601String(),
      log.eventType.name,
      log.severity.name,
      log.action,
      log.entityType,
      log.entityId,
      log.result.name,
      log.title,
      log.description,
      log.oldValue,
      log.newValue,
      jsonEncode(log.metadata),
      log.screen,
      log.errorCode,
      log.errorMessage,
      log.durationMs,
    ]);
    stmt.dispose();
  }

  Future<List<AuditLog>> getLogs({
    String? searchQuery,
    String? entityTypeFilter,
    AuditSeverity? severityFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool ascending = false,
    int? limit,
  }) async {
    final conditions = <String>[];
    final params = <Object?>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      conditions.add(
        '(LOWER(title) LIKE ? OR LOWER(description) LIKE ? OR LOWER(event_type) LIKE ? OR LOWER(entity_type) LIKE ? OR LOWER(COALESCE(entity_id, "")) LIKE ? OR LOWER(COALESCE(error_message, "")) LIKE ? OR LOWER(COALESCE(old_value, "")) LIKE ? OR LOWER(COALESCE(new_value, "")) LIKE ?)',
      );
      params.addAll([q, q, q, q, q, q, q, q]);
    }

    if (entityTypeFilter != null && entityTypeFilter.toLowerCase() != 'all') {
      conditions.add('LOWER(entity_type) = ?');
      params.add(entityTypeFilter.toLowerCase());
    }

    if (severityFilter != null) {
      conditions.add('severity = ?');
      params.add(severityFilter.name);
    }

    if (startDate != null) {
      conditions.add('timestamp >= ?');
      params.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('timestamp <= ?');
      params.add(endDate.toIso8601String());
    }

    var sql = 'SELECT $_selectColumns FROM audit_logs';
    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }
    sql += ' ORDER BY timestamp ${ascending ? 'ASC' : 'DESC'}, id DESC';
    if (limit != null && limit > 0) {
      sql += ' LIMIT $limit';
    }

    final stmt = db.rawDb.prepare(sql);
    final rows = stmt.select(params);
    stmt.dispose();

    return rows.map(_mapRowToAuditLog).toList();
  }

  Future<List<AuditLog>> getEntityHistory(String entityType, String entityId) async {
    final stmt = db.rawDb.prepare('''
      SELECT $_selectColumns FROM audit_logs
      WHERE LOWER(entity_type) = ? AND entity_id = ?
      ORDER BY timestamp DESC, id DESC
    ''');
    final rows = stmt.select([entityType.toLowerCase(), entityId]);
    stmt.dispose();
    return rows.map(_mapRowToAuditLog).toList();
  }

  Future<Map<String, int>> getTodaySummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final stmt = db.rawDb.prepare('''
      SELECT severity, result, COUNT(*) as count FROM audit_logs
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY severity, result
    ''');
    final rows = stmt.select([startOfDay, endOfDay]);
    stmt.dispose();

    int total = 0;
    int changes = 0;
    int warnings = 0;
    int errors = 0;

    for (final r in rows) {
      final c = (r['count'] as num).toInt();
      total += c;
      final sev = r['severity'] as String;
      final res = r['result'] as String;

      if (sev == 'warning') warnings += c;
      if (sev == 'error' || sev == 'critical' || res == 'failed') errors += c;
      if (res == 'success' && (sev == 'success' || sev == 'info')) changes += c;
    }

    return {
      'total': total,
      'changes': changes,
      'warnings': warnings,
      'errors': errors,
    };
  }

  Future<int> deleteLogsOlderThanDays(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final stmt = db.rawDb.prepare('DELETE FROM audit_logs WHERE timestamp < ?');
    stmt.execute([cutoff]);
    stmt.dispose();
    return db.rawDb.updatedRows;
  }

  Future<void> clearAllLogs() async {
    db.rawDb.execute('DELETE FROM audit_logs');
  }

  AuditLog _mapRowToAuditLog(dynamic r) {
    Map<String, dynamic> meta;
    try {
      meta = Map<String, dynamic>.from(jsonDecode(r['metadata'] as String) as Map);
    } catch (_) {
      meta = {};
    }

    return AuditLog(
      id: r['id'] as String,
      timestamp: DateTime.parse(r['timestamp'] as String),
      eventType: AuditEventType.values.firstWhere(
        (e) => e.name == r['event_type'],
        orElse: () => AuditEventType.system,
      ),
      severity: AuditSeverity.values.firstWhere(
        (e) => e.name == r['severity'],
        orElse: () => AuditSeverity.info,
      ),
      action: r['action'] as String? ?? 'UNKNOWN',
      entityType: r['entity_type'] as String? ?? 'SYSTEM',
      entityId: r['entity_id'] as String?,
      result: AuditResult.values.firstWhere(
        (e) => e.name == r['result'],
        orElse: () => AuditResult.success,
      ),
      title: r['title'] as String? ?? '',
      description: r['description'] as String? ?? '',
      oldValue: r['old_value'] as String?,
      newValue: r['new_value'] as String?,
      metadata: meta,
      screen: r['screen'] as String?,
      errorCode: r['error_code'] as String?,
      errorMessage: r['error_message'] as String?,
      durationMs: (r['duration_ms'] as num?)?.toInt(),
    );
  }
}
