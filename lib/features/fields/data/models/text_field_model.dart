import '../../domain/entities/text_field_entity.dart';

class TextFieldModel extends TextFieldEntity {
  const TextFieldModel({
    required super.id,
    required super.idWidget,
    required super.label,
    required super.isRequired,
    required super.inputType,
    super.regex,
    super.maxLength,
    super.minLength,
  });

  factory TextFieldModel.fromJson(Map<String, dynamic> json) {
    return TextFieldModel(
      id: json['id'] as int,
      idWidget: (json['id_widget'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      isRequired: (json['is_required'] ?? false) as bool,
      inputType: (json['input_type'] ?? 'text') as String,
      regex: json['regex'] as String?,
      maxLength: json['max_length'] as int?,
      minLength: json['min_length'] as int?,
    );
  }
}
