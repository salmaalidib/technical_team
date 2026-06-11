import 'package:equatable/equatable.dart';

class TextFieldEntity extends Equatable {
  final int id;
  final String idWidget;
  final String label;
  final bool isRequired;
  final String inputType;
  final String? regex;
  final int? maxLength;
  final int? minLength;

  const TextFieldEntity({
    required this.id,
    required this.idWidget,
    required this.label,
    required this.isRequired,
    required this.inputType,
    this.regex,
    this.maxLength,
    this.minLength,
  });

  @override
  List<Object?> get props =>
      [id, idWidget, label, isRequired, inputType, regex, maxLength, minLength];
}
