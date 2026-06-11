import 'package:equatable/equatable.dart';

class DatePickerEntity extends Equatable {
  final int id;
  final String idWidget;
  final String label;
  final bool isRequired;
  final String minDate;
  final String maxDate;

  const DatePickerEntity({
    required this.id,
    required this.idWidget,
    required this.label,
    required this.isRequired,
    required this.minDate,
    required this.maxDate,
  });

  @override
  List<Object?> get props =>
      [id, idWidget, label, isRequired, minDate, maxDate];
}
