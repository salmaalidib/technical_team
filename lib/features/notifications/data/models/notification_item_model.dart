import '../../domain/entities/notification_item.dart';

/// يحوّل عنصر `NotificationListItemDTO` القادم من الخادم (snake_case) إلى كيان.
class NotificationItemModel {
  const NotificationItemModel._();

  static NotificationItem fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _int(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString(),
      channel: json['channel']?.toString(),
      status: json['status']?.toString(),
      senderName: json['sent_by'] is Map
          ? (json['sent_by'] as Map)['user_name']?.toString()
          : null,
      // الخادم يشتقّ is_read من read_at؛ نقبل غياب الحقل بالرجوع إلى read_at.
      isRead: json['is_read'] == true || json['read_at'] != null,
      readAt: _date(json['read_at']),
      createdAt: _date(json['created_at']),
      transactionId: _int(json['transaction_id']),
      processInstanceId: _int(json['process_instance_id']),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
