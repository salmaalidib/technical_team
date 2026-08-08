import '../../domain/entities/permission.dart';

class PermissionModel extends Permission {
  const PermissionModel({
    required super.id,
    required super.name,
    required super.code,
    required super.type,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    final name = ((json['name'] ?? '') as String).trim();
    final code = ((json['code'] as String?) ?? '').trim();

    return PermissionModel(
      id: (json['id'] ?? 0) as int,
      // Legacy rows (pre-`code` schema) sent the technical code in `name` and
      // the Arabic label in `display_name` — mirror the backend's fix-up
      // migration (code = name) when `code` is absent.
      name: code.isEmpty
          ? ((json['display_name'] as String?)?.trim().isNotEmpty == true
              ? (json['display_name'] as String).trim()
              : name)
          : name,
      code: code.isEmpty ? name : code,
      type: ((json['type'] as String?) ?? '').trim(),
    );
  }
}
