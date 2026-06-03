import 'package:equatable/equatable.dart';

abstract class FieldsEvent extends Equatable {
  const FieldsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFields extends FieldsEvent {
  const LoadFields();
}

/// Creates a field when [id] is null, otherwise updates it.
class SaveFieldRequested extends FieldsEvent {
  final int? id;
  final String name;
  final String type;
  final List<String>? listValues;

  const SaveFieldRequested({
    this.id,
    required this.name,
    required this.type,
    this.listValues,
  });

  @override
  List<Object?> get props => [id, name, type, listValues];
}
