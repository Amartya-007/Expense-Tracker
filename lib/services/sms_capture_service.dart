import 'package:flutter/services.dart';

class SmsCaptureMessage {
  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;

  const SmsCaptureMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
  });

  factory SmsCaptureMessage.fromMap(Map<dynamic, dynamic> map) {
    final timestamp = (map['receivedAt'] as num?)?.toInt() ?? 0;
    return SmsCaptureMessage(
      id: map['id'] as String? ?? '',
      sender: map['sender'] as String? ?? '',
      body: map['body'] as String? ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}

class SmsCaptureService {
  static const _channel = MethodChannel('expensetracker/sms');

  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasSmsPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestSmsPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<List<SmsCaptureMessage>> readPendingMessages() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('readPendingSms');
      return (raw ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map(SmsCaptureMessage.fromMap)
          .where((message) => message.id.isNotEmpty && message.body.isNotEmpty)
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  static Future<void> acknowledgeMessages(Iterable<String> ids) async {
    final messageIds = ids.where((id) => id.isNotEmpty).toList();
    if (messageIds.isEmpty) return;

    try {
      await _channel.invokeMethod<void>('acknowledgePendingSms', messageIds);
    } on PlatformException {
      // Messages remain pending when acknowledgement fails and are retried on
      // the next app launch.
    } on MissingPluginException {
      // Messages remain pending when acknowledgement fails and are retried on
      // the next app launch.
    }
  }
}
