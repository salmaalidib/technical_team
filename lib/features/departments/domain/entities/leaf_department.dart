import 'package:equatable/equatable.dart';

/// A leaf department (one with no children) returned by
/// `GET /api/department/by-organization/:organizationId/leaves`.
///
/// [name] is the full path from the root, e.g. `قسم المحاسبة\شعبة التدقيق`.
class LeafDepartment extends Equatable {
  final int id;
  final String name;

  const LeafDepartment({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
