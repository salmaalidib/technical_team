import '../../domain/entities/field_option.dart';
import '../../domain/entities/text_dropdown_entity.dart';

class TextDropdownModel extends TextDropdownEntity {
  const TextDropdownModel({
    required super.id,
    required super.idWidget,
    required super.label,
    required super.isRequired,
    required super.options,
  });

  factory TextDropdownModel.fromJson(Map<String, dynamic> json) {
    return TextDropdownModel(
      id: json['id'] as int,
      idWidget: (json['id_widget'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      isRequired: (json['is_required'] ?? false) as bool,
      options: FieldOption.listFromJson(json['options']),
    );
  }
}
