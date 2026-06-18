import 'package:equatable/equatable.dart';

/// A single row of `GET /api/process_definitions/admin/review-queue` — a
/// process that is either not yet approved or currently inactive, surfaced to
/// the technical team's review tab.
class ReviewQueueItem extends Equatable {
  final int id;
  final String name;

  /// `approval_status` value (null | "PENDING" | "APPROVED" | "REJECTED").
  final String? status;
  final bool isApproved;
  final bool isActive;

  const ReviewQueueItem({
    required this.id,
    required this.name,
    this.status,
    required this.isApproved,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, status, isApproved, isActive];
}
