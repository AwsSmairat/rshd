import 'dart:convert';

import '../../features/notifications/data/models/notification_model.dart';

/// A push message as the app sees it: the data block the server sends plus
/// the visible title and body.
class PushMessage {
  const PushMessage({required this.data, this.title, this.body});

  final Map<String, dynamic> data;
  final String? title;
  final String? body;

  /// The account this push was sent to; null for a push without one.
  int? get ownerId => int.tryParse('${data['user_id'] ?? ''}');

  /// The in-app notification it belongs to, built from the payload so the
  /// existing [NotificationNavigation] can open it. Null when the payload
  /// isn't one of ours.
  NotificationModel? toNotification() {
    final type = data['type']?.toString();
    if (type == null || type.isEmpty) {
      return null;
    }

    return NotificationModel(
      id: int.tryParse('${data['notification_id'] ?? ''}') ?? 0,
      userId: ownerId ?? 0,
      title: (data['title'] ?? title ?? '').toString(),
      body: (data['body'] ?? body)?.toString(),
      type: type,
      data: _targetData(data['rshd_data']),
    );
  }

  static Map<String, dynamic> _targetData(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } on FormatException {
        // A malformed payload just opens the list for its type.
      }
    }
    return const {};
  }

  String encode() => jsonEncode({'data': data, 'title': title, 'body': body});

  static PushMessage? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return PushMessage(
        data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
        title: map['title']?.toString(),
        body: map['body']?.toString(),
      );
    } on Object {
      return null;
    }
  }
}
