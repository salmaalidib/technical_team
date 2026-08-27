import 'package:equatable/equatable.dart';

/// إشعار واحد كما يعيده `GET /api/notifications/my`.
///
/// الخادم يشتق `is_read` من `read_at` (انظر `NotificationListItemDTO`)، فنقرأ
/// العَلَم مباشرةً ونحتفظ بـ [readAt] للعرض فقط.
class NotificationItem extends Equatable {
  final int id;
  final String title;
  final String message;

  /// نوع الحدث، مثل `transaction_rejected` — يُستخدم لاختيار الأيقونة.
  final String? type;

  /// قناة الإرسال (`in_app`, `email` ...) وحالة الإرسال كما يعيدها الخادم.
  final String? channel;
  final String? status;

  /// مُرسِل الإشعار — `sent_by` في الاستجابة؛ `null` للإشعارات الآلية.
  final String? senderName;

  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  /// معرّفات الربط: تسمح بالتنقّل إلى المعاملة عند الضغط على الإشعار.
  final int? transactionId;
  final int? processInstanceId;

  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.channel,
    this.status,
    this.senderName,
    this.isRead = false,
    this.readAt,
    this.createdAt,
    this.transactionId,
    this.processInstanceId,
    this.metadata,
  });

  NotificationItem copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      channel: channel,
      status: status,
      senderName: senderName,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      transactionId: transactionId,
      processInstanceId: processInstanceId,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        channel,
        status,
        senderName,
        isRead,
        readAt,
        createdAt,
        transactionId,
        processInstanceId,
        metadata,
      ];
}
