import '../../domain/entities/date_picker_entity.dart';

class DatePickerModel extends DatePickerEntity {
  const DatePickerModel({
    required super.id,
    required super.idWidget,
    required super.label,
    required super.isRequired,
    required super.minDate,
    required super.maxDate,
  });

  factory DatePickerModel.fromJson(Map<String, dynamic> json) {
    return DatePickerModel(
      id: json['id'] as int,
      idWidget: (json['id_widget'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      isRequired: (json['is_required'] ?? false) as bool,
      minDate: (json['min_date'] ?? '') as String,
      maxDate: (json['max_date'] ?? '') as String,
    );
  }
}
