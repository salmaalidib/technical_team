import '../../domain/entities/check_list_entity.dart';
import '../../domain/entities/field_option.dart';

class CheckListModel extends CheckListEntity {
  const CheckListModel({
    required super.id,
    required super.idWidget,
    required super.label,
    required super.isRequired,
    required super.minSelected,
    required super.maxSelected,
    required super.options,
  });

  factory CheckListModel.fromJson(Map<String, dynamic> json) {
    return CheckListModel(
      id: json['id'] as int,
      idWidget: (json['id_widget'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      isRequired: (json['is_required'] ?? false) as bool,
      minSelected: (json['min_selected'] ?? 0) as int,
      maxSelected: (json['max_selected'] ?? 1) as int,
      options: FieldOption.listFromJson(json['options']),
    );
  }
}
