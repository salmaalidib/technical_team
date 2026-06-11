import 'package:equatable/equatable.dart';

import 'field_option.dart';

class TextDropdownEntity extends Equatable {
  final int id;
  final String idWidget;
  final String label;
  final bool isRequired;
  final List<FieldOption> options;

  const TextDropdownEntity({
    required this.id,
    required this.idWidget,
    required this.label,
    required this.isRequired,
    required this.options,
  });

  @override
  List<Object?> get props => [id, idWidget, label, isRequired, options];
}
