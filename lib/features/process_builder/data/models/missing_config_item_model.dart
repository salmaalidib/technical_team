import '../../domain/entities/missing_config_item.dart';

class MissingConfigItemModel extends MissingConfigItem {
  const MissingConfigItemModel({
    required super.id,
    required super.name,
    super.status,
    required super.isApproved,
    required super.isActive,
    required super.stagesTotalCount,
    required super.stagesMissingConfigCount,
  });

  factory MissingConfigItemModel.fromJson(Map<String, dynamic> json) {
    return MissingConfigItemModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      status: json['status'] as String?,
      isApproved: json['is_approved'] == true,
      isActive: json['is_active'] == true,
      stagesTotalCount: (json['stages_total_count'] as num?)?.toInt() ?? 0,
      stagesMissingConfigCount:
          (json['stages_missing_config_count'] as num?)?.toInt() ?? 0,
    );
  }
}
