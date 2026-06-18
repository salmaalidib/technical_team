import '../../domain/entities/review_queue_item.dart';

class ReviewQueueItemModel extends ReviewQueueItem {
  const ReviewQueueItemModel({
    required super.id,
    required super.name,
    super.status,
    required super.isApproved,
    required super.isActive,
  });

  factory ReviewQueueItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewQueueItemModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      status: json['status'] as String?,
      isApproved: json['is_approved'] == true,
      isActive: json['is_active'] == true,
    );
  }
}
