import 'package:equatable/equatable.dart';

import '../../domain/entities/form_config.dart';

abstract class TemplatesEvent extends Equatable {
  const TemplatesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads page 1 of the active document-templates list.
///
/// [limit] lets a caller that needs the whole list in one shot (the wizard's
/// template picker, which must render already-linked templates) ask for a
/// large page instead of the server default of 10.
class LoadTemplates extends TemplatesEvent {
  final int limit;

  const LoadTemplates({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

/// Debounced search over the templates list — reloads page 1 with the term.
class TemplatesSearchChanged extends TemplatesEvent {
  final String query;

  const TemplatesSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Appends the next page (infinite scroll). No-op when a load is already in
/// flight or the last page has been reached.
class TemplatesNextPageRequested extends TemplatesEvent {
  const TemplatesNextPageRequested();
}

/// Resets the form/wizard status (called when opening the create/edit form).
class ResetTemplateForm extends TemplatesEvent {
  const ResetTemplateForm();
}

/// Create step 1 — uploads the picked PDF via
/// `POST /api/document-templates/extract-fields` and, on success, stores the
/// returned `path`/`url` and extracted fields in the state so step 2 can render
/// the field-linking cards. No template row exists yet.
class ExtractFromUploadRequested extends TemplatesEvent {
  final List<int> fileBytes;
  final String fileName;

  const ExtractFromUploadRequested({
    required this.fileBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [fileName];
}

/// Create step 2 — creates the fully-configured template in one JSON call via
/// `POST /api/document-templates` using the `path`/`url` captured in step 1.
class CreateTemplateRequested extends TemplatesEvent {
  final String name;
  final int typeDocId;
  final FormConfig config;

  const CreateTemplateRequested({
    required this.name,
    required this.typeDocId,
    required this.config,
  });

  @override
  List<Object?> get props => [name, typeDocId, config];
}

/// Loads the extracted PDF fields of an **existing** template [id] via
/// `GET /api/document-templates/{id}/fields`. Used only by the edit form.
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
