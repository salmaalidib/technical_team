import 'package:equatable/equatable.dart';

import 'process_stage.dart';

/// The result of `POST /api/process_definitions/create`: the freshly deployed
/// process plus the stages auto-generated from its BPMN by Camunda.
class CreatedProcess extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? status;
  final List<ProcessStage> stages;

  const CreatedProcess({
    required this.id,
    required this.name,
    this.code,
    this.status,
    this.stages = const [],
  });

  @override
  List<Object?> get props => [id, name, code, status, stages];
}
