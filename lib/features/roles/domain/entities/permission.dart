import 'package:equatable/equatable.dart';

/// A single permission row from `GET /api/auth/permissions`.
///
/// [name] is the technical code the backend matches inside `authorize()`
/// (e.g. `ROLE_PERMISSION_CREATE`) and is never shown to the user.
/// [displayName] is the Arabic label; the server already falls back to [name]
/// when a permission has no translation yet, so it is never empty.
class Permission extends Equatable {
  final int id;
  final String name;
  final String displayName;

  const Permission({
    required this.id,
    required this.name,
    required this.displayName,
  });

  @override
  List<Object?> get props => [id, name, displayName];
}
