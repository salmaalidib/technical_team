import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/type_doc.dart';

class TypeDocsState extends Equatable {
  /// Document-types list load.
  final RequestStatus status;
  final List<TypeDoc> typeDocs;
  final String? error;

  /// Create / rename submission (dialog-driven).
  final FormStatus formStatus;
  final String? formError;

  /// Ids whose (de)activation is in flight.
  final Set<int> busyIds;

  /// One-shot message for inline action errors (deactivate), shown as a snackbar.
  final String? actionError;

  /// One-shot id of the just-created type, used to auto-select it in the
  /// dropdown.
  final int? lastCreatedId;

  const TypeDocsState({
    this.status = RequestStatus.initial,
    this.typeDocs = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.busyIds = const {},
    this.actionError,
    this.lastCreatedId,
  });

  TypeDocsState copyWith({
    RequestStatus? status,
    List<TypeDoc>? typeDocs,
    String? error,
    FormStatus? formStatus,
    String? formError,
    Set<int>? busyIds,
    String? actionError,
    int? lastCreatedId,
  }) {
    return TypeDocsState(
      status: status ?? this.status,
      typeDocs: typeDocs ?? this.typeDocs,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      busyIds: busyIds ?? this.busyIds,
      actionError: actionError,
      lastCreatedId: lastCreatedId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        typeDocs,
        error,
        formStatus,
        formError,
        busyIds,
        actionError,
        lastCreatedId,
      ];
}
