import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/doc_template.dart';
import '../../domain/entities/extracted_field.dart';

class TemplatesState extends Equatable {
  /// List load.
  final RequestStatus status;
  final List<DocTemplate> templates;
  final String? error;

  /// Step 1 — create (file + meta). On success [createdTemplate] holds the new
  /// row so the wizard can advance to step 2 with its id.
  final FormStatus createStatus;
  final String? createError;
  final DocTemplate? createdTemplate;

  /// Extracted PDF fields for the current template (loaded between the steps).
  final RequestStatus extractStatus;
  final List<ExtractedField> extractedFields;
  final String? extractError;

  /// Create flow only — the `path`/`url` returned by the upload step. They are
  /// sent back verbatim in the final create call. Null on the edit flow (which
  /// has no upload).
  final String? uploadedPath;
  final String? uploadedUrl;

  /// Step 2 — config save (PUT). Kept separate from create so the wizard can
  /// tell "row created" apart from "config saved".
  final FormStatus configStatus;
  final String? configError;

  /// Set after a successful config save so the form page can pop and the list
  /// reflects the latest version. Reset by [ResetTemplateForm].
  final int? lastSavedId;

  const TemplatesState({
    this.status = RequestStatus.initial,
    this.templates = const [],
    this.error,
    this.createStatus = FormStatus.idle,
    this.createError,
    this.createdTemplate,
    this.extractStatus = RequestStatus.initial,
    this.extractedFields = const [],
    this.extractError,
    this.uploadedPath,
    this.uploadedUrl,
    this.configStatus = FormStatus.idle,
    this.configError,
    this.lastSavedId,
  });

  TemplatesState copyWith({
    RequestStatus? status,
    List<DocTemplate>? templates,
    String? error,
    FormStatus? createStatus,
    String? createError,
    DocTemplate? createdTemplate,
    RequestStatus? extractStatus,
    List<ExtractedField>? extractedFields,
    String? extractError,
    String? uploadedPath,
    String? uploadedUrl,
    FormStatus? configStatus,
    String? configError,
    int? lastSavedId,
    bool clearWizard = false,
  }) {
    return TemplatesState(
      status: status ?? this.status,
      templates: templates ?? this.templates,
      error: error,
      createStatus:
          clearWizard ? FormStatus.idle : (createStatus ?? this.createStatus),
      createError: clearWizard ? null : createError,
      createdTemplate:
          clearWizard ? null : (createdTemplate ?? this.createdTemplate),
      extractStatus: clearWizard
          ? RequestStatus.initial
          : (extractStatus ?? this.extractStatus),
      extractedFields:
          clearWizard ? const [] : (extractedFields ?? this.extractedFields),
      extractError: clearWizard ? null : extractError,
      uploadedPath: clearWizard ? null : (uploadedPath ?? this.uploadedPath),
      uploadedUrl: clearWizard ? null : (uploadedUrl ?? this.uploadedUrl),
      configStatus:
          clearWizard ? FormStatus.idle : (configStatus ?? this.configStatus),
      configError: clearWizard ? null : configError,
      lastSavedId: clearWizard ? null : (lastSavedId ?? this.lastSavedId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        templates,
        error,
        createStatus,
        createError,
        createdTemplate,
        extractStatus,
        extractedFields,
        extractError,
        uploadedPath,
        uploadedUrl,
        configStatus,
        configError,
        lastSavedId,
      ];
}
