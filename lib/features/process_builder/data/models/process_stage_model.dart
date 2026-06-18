import '../../domain/entities/process_stage.dart';

class ProcessStageModel extends ProcessStage {
  const ProcessStageModel({
    required super.id,
    required super.name,
    required super.code,
    required super.type,
    required super.authType,
  });

  factory ProcessStageModel.fromJson(Map<String, dynamic> json) {
    return ProcessStageModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? json['camunda_task_key'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      authType: (json['auth_type'] ?? 'NOAUTH') as String,
    );
  }
}
