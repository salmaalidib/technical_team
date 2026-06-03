import '../../domain/entities/dynamic_field.dart';

class DynamicFieldModel extends DynamicField {
  const DynamicFieldModel({
    required super.id,
    required super.fieldName,
    required super.fieldType,
    super.listValues,
  });

  factory DynamicFieldModel.fromJson(Map<String, dynamic> json) {
    final raw = json['list_json'];
    final values = raw is List ? raw.map((e) => e.toString()).toList() : null;

    return DynamicFieldModel(
      id: json['id'] as int,
      fieldName: (json['field_name'] ?? '') as String,
      fieldType: (json['field_type'] ?? '') as String,
      listValues: values,
    );
  }
}
