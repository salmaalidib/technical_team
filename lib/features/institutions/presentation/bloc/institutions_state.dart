import 'package:equatable/equatable.dart';

import '../../domain/entities/institution.dart';
import '../../domain/entities/location_option.dart';

enum InstitutionsStatus { initial, loading, success, failure }

/// Status of the create-institution form submission.
enum InstitutionFormStatus { idle, submitting, success, failure }

class InstitutionsState extends Equatable {
  final InstitutionsStatus status;
  final List<Institution> institutions;
  final List<LocationOption> locations;
  final String? error;

  final InstitutionFormStatus formStatus;
  final String? formError;

  const InstitutionsState({
    this.status = InstitutionsStatus.initial,
    this.institutions = const [],
    this.locations = const [],
    this.error,
    this.formStatus = InstitutionFormStatus.idle,
    this.formError,
  });

  InstitutionsState copyWith({
    InstitutionsStatus? status,
    List<Institution>? institutions,
    List<LocationOption>? locations,
    String? error,
    InstitutionFormStatus? formStatus,
    String? formError,
  }) {
    return InstitutionsState(
      status: status ?? this.status,
      institutions: institutions ?? this.institutions,
      locations: locations ?? this.locations,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
    );
  }

  @override
  List<Object?> get props =>
      [status, institutions, locations, error, formStatus, formError];
}
