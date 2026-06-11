import '../../domain/entities/field_option.dart';
import '../../domain/entities/radio_group_entity.dart';

class RadioGroupModel extends RadioGroupEntity {
  const RadioGroupModel({
    required super.id,
    required super.idWidget,
    required super.label,
    required super.isRequired,
    required super.options,
  });

  factory RadioGroupModel.fromJson(Map<String, dynamic> json) {
    return RadioGroupModel(
      id: json['id'] as int,
      idWidget: (json['id_widget'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      isRequired: (json['is_required'] ?? false) as bool,
      options: FieldOption.listFromJson(json['options']),
    );
  }
}
