import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/dynamic_field.dart';

class FieldsState extends Equatable {
  final RequestStatus status;
  final List<DynamicField> fields;
  final String? error;

  /// Create / edit form submission.
  final FormStatus formStatus;
  final String? formError;

  const FieldsState({
    this.status = RequestStatus.initial,
    this.fields = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
  });

  FieldsState copyWith({
    RequestStatus? status,
    List<DynamicField>? fields,
    String? error,
    FormStatus? formStatus,
    String? formError,
  }) {
    return FieldsState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
    );
  }

  @override
  List<Object?> get props => [status, fields, error, formStatus, formError];
}
