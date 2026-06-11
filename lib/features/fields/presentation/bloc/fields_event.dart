import 'package:equatable/equatable.dart';

import '../../domain/entities/field_type.dart';

abstract class FieldsEvent extends Equatable {
  const FieldsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllFields extends FieldsEvent {
  const LoadAllFields();
}

class SelectFieldType extends FieldsEvent {
  final FieldType type;

  const SelectFieldType(this.type);

  @override
  List<Object?> get props => [type];
}

class CreateFieldRequested extends FieldsEvent {
  final FieldType type;
  final Map<String, dynamic> body;

  const CreateFieldRequested({required this.type, required this.body});

  @override
  List<Object?> get props => [type, body];
}
