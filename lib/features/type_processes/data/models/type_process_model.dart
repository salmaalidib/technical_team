import '../../domain/entities/type_process.dart';

class TypeProcessModel extends TypeProcess {
  const TypeProcessModel({
    required super.id,
    required super.name,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory TypeProcessModel.fromJson(Map<String, dynamic> json) {
    return TypeProcessModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      isActive: (json['is_active'] ?? true) as bool,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
