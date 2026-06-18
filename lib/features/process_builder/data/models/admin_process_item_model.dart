import '../../domain/entities/admin_process_item.dart';

class AdminProcessItemModel extends AdminProcessItem {
  const AdminProcessItemModel({
    required super.processId,
    required super.name,
    super.code,
    super.priority,
    super.deploymentStatus,
    super.approvalStatus,
    required super.isActive,
  });

  factory AdminProcessItemModel.fromJson(Map<String, dynamic> json) {
    return AdminProcessItemModel(
      processId: (json['process_id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      code: json['code'] as String?,
      priority: (json['priority'] as num?)?.toInt(),
      deploymentStatus: json['deployment_status'] as String?,
      approvalStatus: json['approval_status'] as String?,
      isActive: json['is_active'] == true,
    );
  }
}
