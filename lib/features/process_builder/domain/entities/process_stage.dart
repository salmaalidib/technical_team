import 'package:equatable/equatable.dart';

/// A single stage generated from the uploaded BPMN, returned by
/// `POST /api/process_definitions/create` (and the details endpoint).
///
/// [type] is `USER_TASK` or `SERVICE_TASK`; [authType] is `AUTH` (the first
/// user task — the citizen/applicant submission) or `NOAUTH`. The customization
/// editor adapts entirely to these two flags, never to hard-coded stage names.
class ProcessStage extends Equatable {
  final int id;
  final String name;
  final String code;
  final String type;
  final String authType;

  const ProcessStage({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.authType,
  });

  bool get isUserTask => type == 'USER_TASK';
  bool get isServiceTask => type == 'SERVICE_TASK';
  bool get isAuth => authType == 'AUTH';

  @override
  List<Object?> get props => [id, name, code, type, authType];
}
