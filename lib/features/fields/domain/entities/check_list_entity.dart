import 'package:equatable/equatable.dart';

import 'field_option.dart';

class CheckListEntity extends Equatable {
  final int id;
  final String idWidget;
  final String label;
  final bool isRequired;
  final int minSelected;
  final int maxSelected;
  final List<FieldOption> options;

  const CheckListEntity({
    required this.id,
    required this.idWidget,
    required this.label,
    required this.isRequired,
    required this.minSelected,
    required this.maxSelected,
    required this.options,
  });

  @override
  List<Object?> get props =>
      [id, idWidget, label, isRequired, minSelected, maxSelected, options];
}
