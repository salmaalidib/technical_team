import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/location_option.dart';

class InstitutionsState extends Equatable {
  final RequestStatus status;
  final List<Institution> institutions;
  final List<LocationOption> locations;
  final String? error;

  final FormStatus formStatus;
  final String? formError;

  /// Separate status for the "add location" form so it never collides with the
  /// institution create form.
  final FormStatus locationFormStatus;
  final String? locationFormError;

  const InstitutionsState({
    this.status = RequestStatus.initial,
    this.institutions = const [],
    this.locations = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.locationFormStatus = FormStatus.idle,
    this.locationFormError,
  });

  InstitutionsState copyWith({
    RequestStatus? status,
    List<Institution>? institutions,
    List<LocationOption>? locations,
    String? error,
    FormStatus? formStatus,
    String? formError,
    FormStatus? locationFormStatus,
    String? locationFormError,
  }) {
    return InstitutionsState(
      status: status ?? this.status,
      institutions: institutions ?? this.institutions,
      locations: locations ?? this.locations,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      locationFormStatus: locationFormStatus ?? this.locationFormStatus,
      locationFormError: locationFormError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        institutions,
        locations,
        error,
        formStatus,
        formError,
        locationFormStatus,
        locationFormError,
      ];
}
