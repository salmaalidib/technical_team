import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/file_definition.dart';

class FilesState extends Equatable {
  final RequestStatus status;
  final List<FileDefinition> files;
  final String? error;

  /// Create / edit form submission.
  final FormStatus formStatus;
  final String? formError;

  const FilesState({
    this.status = RequestStatus.initial,
    this.files = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
  });

  FilesState copyWith({
    RequestStatus? status,
    List<FileDefinition>? files,
    String? error,
    FormStatus? formStatus,
    String? formError,
  }) {
    return FilesState(
      status: status ?? this.status,
      files: files ?? this.files,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
    );
  }

  @override
  List<Object?> get props => [status, files, error, formStatus, formError];
}
