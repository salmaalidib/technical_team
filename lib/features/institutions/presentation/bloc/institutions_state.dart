import 'package:equatable/equatable.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/location_option.dart';
import '../../domain/entities/type_location_option.dart';

/// One hop in the drill-down trail (root -> parent -> sub-institution ...).
class InstitutionCrumb extends Equatable {
  final int id;
  final String name;

  const InstitutionCrumb({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class InstitutionsState extends Equatable {
  final RequestStatus status;
  final List<Institution> institutions;
  final List<LocationOption> locations;

  /// Location types from `GET /api/type-location`. Their own list (not derived
  /// from [locations]) so a freshly-created type with no locations still shows.
  final List<TypeLocationOption> typeLocations;
  final String? error;

  final FormStatus formStatus;
  final String? formError;

  /// Separate status for the "add location" form so it never collides with the
  /// institution create form.
  final FormStatus locationFormStatus;
  final String? locationFormError;

  /// Separate again for the nested "add location type" form.
  final FormStatus typeLocationFormStatus;
  final String? typeLocationFormError;

  /// Drill-down trail. Empty == root level (top-level institutions).
  final List<InstitutionCrumb> breadcrumb;

  /// Client-side search within the current level.
  final String searchQuery;

  /// Client-side pagination (1-based) of the current level.
  final int currentPage;
  final int pageSize;

  const InstitutionsState({
    this.status = RequestStatus.initial,
    this.institutions = const [],
    this.locations = const [],
    this.typeLocations = const [],
    this.error,
    this.formStatus = FormStatus.idle,
    this.formError,
    this.locationFormStatus = FormStatus.idle,
    this.locationFormError,
    this.typeLocationFormStatus = FormStatus.idle,
    this.typeLocationFormError,
    this.breadcrumb = const [],
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 10,
  });

  /// The parent whose children are currently shown, or null at root.
  int? get currentParentId => breadcrumb.isEmpty ? null : breadcrumb.last.id;

  /// Institutions belonging to the current level, after search filtering.
  List<Institution> get levelInstitutions {
    final parentId = currentParentId;
    final query = searchQuery.trim();
    return institutions.where((i) {
      if (i.parentId != parentId) return false;
      if (query.isEmpty) return true;
      return i.name.contains(query);
    }).toList();
  }

  int get pageCount {
    final total = levelInstitutions.length;
    if (total == 0) return 1;
    return (total / pageSize).ceil();
  }

  /// The slice of [levelInstitutions] for [currentPage].
  List<Institution> get pagedInstitutions {
    final level = levelInstitutions;
    final start = (currentPage - 1) * pageSize;
    if (start >= level.length) return const [];
    final end = (start + pageSize).clamp(0, level.length);
    return level.sublist(start, end);
  }

  InstitutionsState copyWith({
    RequestStatus? status,
    List<Institution>? institutions,
    List<LocationOption>? locations,
    List<TypeLocationOption>? typeLocations,
    String? error,
    FormStatus? formStatus,
    String? formError,
    FormStatus? locationFormStatus,
    String? locationFormError,
    FormStatus? typeLocationFormStatus,
    String? typeLocationFormError,
    List<InstitutionCrumb>? breadcrumb,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
  }) {
    return InstitutionsState(
      status: status ?? this.status,
      institutions: institutions ?? this.institutions,
      locations: locations ?? this.locations,
      typeLocations: typeLocations ?? this.typeLocations,
      error: error,
      formStatus: formStatus ?? this.formStatus,
      formError: formError,
      locationFormStatus: locationFormStatus ?? this.locationFormStatus,
      locationFormError: locationFormError,
      typeLocationFormStatus:
          typeLocationFormStatus ?? this.typeLocationFormStatus,
      typeLocationFormError: typeLocationFormError,
      breadcrumb: breadcrumb ?? this.breadcrumb,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        status,
        institutions,
        locations,
        typeLocations,
        error,
        formStatus,
        formError,
        locationFormStatus,
        locationFormError,
        typeLocationFormStatus,
        typeLocationFormError,
        breadcrumb,
        searchQuery,
        currentPage,
        pageSize,
      ];
}
