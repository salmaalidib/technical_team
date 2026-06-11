import 'package:equatable/equatable.dart';

abstract class TypeProcessesEvent extends Equatable {
  const TypeProcessesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the process-types list.
class LoadTypeProcesses extends TypeProcessesEvent {
  const LoadTypeProcesses();
}

class CreateTypeProcessRequested extends TypeProcessesEvent {
  final String name;

  const CreateTypeProcessRequested({required this.name});

  @override
  List<Object?> get props => [name];
}

/// Flips the active flag of a single process type via `PUT /api/typeProcess/{id}`.
class ToggleTypeProcessStatus extends TypeProcessesEvent {
  final int id;
  final bool isActive;

  const ToggleTypeProcessStatus({required this.id, required this.isActive});

  @override
  List<Object?> get props => [id, isActive];
}
