import 'package:equatable/equatable.dart';

/// A role definition from the `roles` table, as returned by
/// `GET /api/role/catalog` — independent of any organization or department.
///
/// This is the option list for the create-role form: picking one links the
/// existing role to a new (organization, department) pair instead of defining
/// a duplicate role under a fresh code.
class RoleCatalogItem extends Equatable {
  final int id;
  final String name;
  final String code;

  const RoleCatalogItem({
    required this.id,
    required this.name,
    required this.code,
  });

  @override
  List<Object?> get props => [id, name, code];
}
