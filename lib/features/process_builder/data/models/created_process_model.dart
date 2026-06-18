import '../../domain/entities/created_process.dart';
import '../../domain/entities/process_stage.dart';
import 'process_stage_model.dart';

class CreatedProcessModel extends CreatedProcess {
  const CreatedProcessModel({
    required super.id,
    required super.name,
    super.code,
    super.status,
    super.stages,
  });

  /// Parses the `data` envelope of `POST /api/process_definitions/create`,
  /// which is `{ success, process, stages }`.
  factory CreatedProcessModel.fromCreateResponse(Map<String, dynamic> data) {
    final process = (data['process'] ?? {}) as Map<String, dynamic>;
    final rawStages = (data['stages'] ?? const []) as List;

    return CreatedProcessModel(
      id: process['id'] as int,
      name: (process['name'] ?? '') as String,
      code: process['code'] as String?,
      status: process['status'] as String?,
      stages: rawStages
          .map<ProcessStage>(
              (e) => ProcessStageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
