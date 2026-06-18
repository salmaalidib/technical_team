import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/created_process.dart';
import '../repositories/process_builder_repository.dart';

class CreateProcessDefinitionUseCase {
  final ProcessBuilderRepository repository;

  CreateProcessDefinitionUseCase(this.repository);

  Future<Either<Failure, CreatedProcess>> call({
    required String name,
    required bool isComplaint,
    int? typeTransId,
    required int organizationId,
    required int priority,
    required String startDate,
    String? endDate,
    required List<int> fileBytes,
    required String fileName,
  }) {
    return repository.createProcessDefinition(
      name: name,
      isComplaint: isComplaint,
      typeTransId: typeTransId,
      organizationId: organizationId,
      priority: priority,
      startDate: startDate,
      endDate: endDate,
      fileBytes: fileBytes,
      fileName: fileName,
    );
  }
}
