import 'package:equatable/equatable.dart';

/// A role available for a specific (leaf) department, as returned by
/// `GET /api/role/by-department/{departmentId}`.
///
/// Used when registering an employee after the department is picked — a
/// lightweight `{ id, name, code }` projection, not the full
/// [RoleAssignment] link row.
class RoleByDepartment extends Equatable {
  final int id;
  final String name;
  final String code;

  const RoleByDepartment({
    required this.id,
    required this.name,
    required this.code,
  });

  @override
  List<Object?> get props => [id, name, code];
}
