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

/// Resets the form/wizard status (called when opening the create/edit form).
class ResetTemplateForm extends TemplatesEvent {
  const ResetTemplateForm();
}

/// Step 1 — creates the template row via `POST /api/document-templates`
/// (file + name + type_doc_id). On success the bloc stores the created
/// template, adds it to the list (still without config), and auto-loads its
/// extracted fields for step 2.
class CreateTemplateRequested extends TemplatesEvent {
  final String name;
  final int typeDocId;
  final List<int> fileBytes;
  final String fileName;

  const CreateTemplateRequested({
    required this.name,
    required this.typeDocId,
    required this.fileBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [name, typeDocId, fileName];
}

/// Loads the extracted PDF fields for [id] via
/// `GET /api/document-templates/{id}/fields`. Dispatched automatically after a
/// successful create, and on opening the edit form for an existing template.
class ExtractFieldsRequested extends TemplatesEvent {
  final int id;

  const ExtractFieldsRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Step 2 — sets `config_json` via `PUT /api/document-templates/{id}`. The
/// backend archives the old version and returns the new one, which replaces the
/// edited row in the list.
class UpdateTemplateConfigRequested extends TemplatesEvent {
  final int id;
  final FormConfig config;

  const UpdateTemplateConfigRequested({
    required this.id,
    required this.config,
  });

  @override
  List<Object?> get props => [id, config];
}
