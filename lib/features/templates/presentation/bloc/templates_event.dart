import 'package:equatable/equatable.dart';

import '../../domain/entities/form_config.dart';

abstract class TemplatesEvent extends Equatable {
  const TemplatesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the active document-templates list.
class LoadTemplates extends TemplatesEvent {
  const LoadTemplates();
}

/// Resets the form status (called when opening the create/edit form).
class ResetTemplateForm extends TemplatesEvent {
  const ResetTemplateForm();
}

/// Creates a new template via `POST /api/document-templates`.
class CreateTemplateRequested extends TemplatesEvent {
  final String name;
  final int typeDocId;
  final FormConfig config;
  final List<int> fileBytes;
  final String fileName;

  const CreateTemplateRequested({
    required this.name,
    required this.typeDocId,
    required this.config,
    required this.fileBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [name, typeDocId, config, fileName];
}

/// Updates a template via `PUT /api/document-templates/{id}`. The file is
/// optional; omit [fileBytes]/[fileName] to keep the existing file.
class UpdateTemplateRequested extends TemplatesEvent {
  final int id;
  final String name;
  final int typeDocId;
  final FormConfig config;
  final List<int>? fileBytes;
  final String? fileName;

  const UpdateTemplateRequested({
    required this.id,
    required this.name,
    required this.typeDocId,
    required this.config,
    this.fileBytes,
    this.fileName,
  });

  @override
  List<Object?> get props => [id, name, typeDocId, config, fileName];
}
