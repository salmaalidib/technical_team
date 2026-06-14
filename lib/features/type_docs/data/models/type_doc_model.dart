import '../../domain/entities/type_doc.dart';

class TypeDocModel extends TypeDoc {
  const TypeDocModel({
    required super.id,
    required super.name,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory TypeDocModel.fromJson(Map<String, dynamic> json) {
    return TypeDocModel(
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
