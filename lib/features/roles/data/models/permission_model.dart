import '../../domain/entities/permission.dart';

class PermissionModel extends Permission {
  const PermissionModel({
    required super.id,
    required super.name,
    required super.displayName,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '') as String;

    return PermissionModel(
      id: (json['id'] ?? 0) as int,
      name: name,
      // The server already falls back to `name`; this guards older responses
      // that predate the display_name column.
      displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
          ? json['display_name'] as String
          : name,
    );
  }
}
