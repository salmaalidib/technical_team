import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/type_process.dart';

class TypeProcessesState extends Equatable {
  /// Process-types list load.
  final RequestStatus status;
  final List<TypeProcess> typeProcesses;
  final String? error;

  /// Create-form submission.
  final FormStatus formStatus;
  final String? formError;

  /// Ids whose status toggle is in flight.
  final Set<int> togglingIds;

  /// One-shot message for action errors (toggle), surfaced as a snackbar.
  final String? actionError;

  const TypeProcessesState({
    this.status = RequestStatus.initial,
    this.typeProcesses = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.togglingIds = const {},
    this.actionError,
  });

  TypeProcessesState copyWith({
    RequestStatus? status,
    List<TypeProcess>? typeProcesses,
    String? error,
    FormStatus? formStatus,
    String? formError,
    Set<int>? togglingIds,
    String? actionError,
  }) {
    return TypeProcessesState(
      status: status ?? this.status,
      typeProcesses: typeProcesses ?? this.typeProcesses,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      togglingIds: togglingIds ?? this.togglingIds,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        typeProcesses,
        error,
        formStatus,
        formError,
        togglingIds,
        actionError,
      ];
}
