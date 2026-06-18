import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/doc_template.dart';

class TemplatesState extends Equatable {
  /// List load.
  final RequestStatus status;
  final List<DocTemplate> templates;
  final String? error;

  /// Create / update submission (kept separate from the list load).
  final FormStatus formStatus;
  final String? formError;

  /// Set after a successful create/update so the form page can pop and the list
  /// can refresh. Reset by [ResetTemplateForm].
  final int? lastSavedId;

  const TemplatesState({
    this.status = RequestStatus.initial,
    this.templates = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.lastSavedId,
  });

  TemplatesState copyWith({
    RequestStatus? status,
    List<DocTemplate>? templates,
    String? error,
    FormStatus? formStatus,
    String? formError,
    int? lastSavedId,
    bool clearLastSaved = false,
  }) {
    return TemplatesState(
      status: status ?? this.status,
      templates: templates ?? this.templates,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      lastSavedId: clearLastSaved ? null : (lastSavedId ?? this.lastSavedId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        templates,
        error,
        formStatus,
        formError,
        lastSavedId,
      ];
}
