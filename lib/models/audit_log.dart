enum AuditEventType {
  create,
  update,
  delete,
  restore,
  transfer,
  split,
  importData,
  exportData,
  validation,
  database,
  calculation,
  settings,
  system,
  error,
}

enum AuditSeverity {
  info,
  success,
  warning,
  error,
  critical,
}

enum AuditResult {
  success,
  failed,
  cancelled,
}

class AuditLog {
  final String id;
  final DateTime timestamp;
  final AuditEventType eventType;
  final AuditSeverity severity;
  final String action;
  final String entityType;
  final String? entityId;
  final AuditResult result;
  final String title;
  final String description;
  final String? oldValue;
  final String? newValue;
  final Map<String, dynamic> metadata;
  final String? screen;
  final String? errorCode;
  final String? errorMessage;
  final int? durationMs;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.eventType,
    this.severity = AuditSeverity.info,
    required this.action,
    required this.entityType,
    this.entityId,
    this.result = AuditResult.success,
    required this.title,
    this.description = '',
    this.oldValue,
    this.newValue,
    this.metadata = const {},
    this.screen,
    this.errorCode,
    this.errorMessage,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType.name,
        'severity': severity.name,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'result': result.name,
        'title': title,
        'description': description,
        'oldValue': oldValue,
        'newValue': newValue,
        'metadata': metadata,
        'screen': screen,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'durationMs': durationMs,
      };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        eventType: AuditEventType.values.firstWhere(
          (e) => e.name == json['eventType'],
          orElse: () => AuditEventType.system,
        ),
        severity: AuditSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => AuditSeverity.info,
        ),
        action: json['action'] as String? ?? 'UNKNOWN',
        entityType: json['entityType'] as String? ?? 'SYSTEM',
        entityId: json['entityId'] as String?,
        result: AuditResult.values.firstWhere(
          (e) => e.name == json['result'],
          orElse: () => AuditResult.success,
        ),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        oldValue: json['oldValue'] as String?,
        newValue: json['newValue'] as String?,
        metadata: (json['metadata'] is Map)
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : {},
        screen: json['screen'] as String?,
        errorCode: json['errorCode'] as String?,
        errorMessage: json['errorMessage'] as String?,
        durationMs: (json['durationMs'] as num?)?.toInt(),
      );
}
