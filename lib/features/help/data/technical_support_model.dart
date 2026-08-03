class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.status,
    required this.statusLabel,
    this.assignedAdminName,
    this.createdAt,
    this.acceptedAt,
    this.closedAt,
  });

  final int id;
  final String status;
  final String statusLabel;
  final String? assignedAdminName;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? closedAt;

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
  bool get isOpen => isPending || isActive;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? '',
      assignedAdminName: json['assigned_admin_name'] as String?,
      createdAt: _parseDate(json['created_at']),
      acceptedAt: _parseDate(json['accepted_at']),
      closedAt: _parseDate(json['closed_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class SupportMessageModel {
  const SupportMessageModel({
    required this.id,
    required this.body,
    required this.isMine,
    this.senderName,
    this.createdAt,
  });

  final int id;
  final String body;
  final bool isMine;
  final String? senderName;
  final DateTime? createdAt;

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      isMine: json['is_mine'] as bool? ?? false,
      senderName: json['sender_name'] as String?,
      createdAt: SupportTicketModel._parseDate(json['created_at']),
    );
  }
}

class SupportConversationModel {
  const SupportConversationModel({
    this.ticket,
    this.messages = const [],
  });

  final SupportTicketModel? ticket;
  final List<SupportMessageModel> messages;

  bool get hasOpenTicket => ticket?.isOpen ?? false;

  factory SupportConversationModel.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'];
    final messagesJson = json['messages'];

    return SupportConversationModel(
      ticket: ticketJson is Map<String, dynamic>
          ? SupportTicketModel.fromJson(ticketJson)
          : null,
      messages: messagesJson is List
          ? messagesJson
              .whereType<Map>()
              .map((item) => SupportMessageModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}
