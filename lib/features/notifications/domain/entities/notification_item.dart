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
        isRead,
        readAt,
        createdAt,
        transactionId,
        processInstanceId,
        metadata,
      ];
}
