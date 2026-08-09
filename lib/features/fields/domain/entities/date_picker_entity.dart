import 'package:equatable/equatable.dart';

import 'date_bound.dart';

class DatePickerEntity extends Equatable {
  final int id;
  final String idWidget;
  final String label;
  final bool isRequired;

  /// Range ends. Each may be an absolute date, "today", or an offset from
  /// today — see [DateBound].
  final DateBound minDate;
  final DateBound maxDate;

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
