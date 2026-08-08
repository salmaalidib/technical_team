import 'package:equatable/equatable.dart';

/// Which backend permission list to fetch.
///
/// Maps to `GET /api/auth/permissions[/employee|/admin]` — the audience routes
/// return their own type plus the shared `employee,citizen,admin` rows, with a
/// Redis cache per audience on the server.
enum PermissionAudience { all, employee, admin }

/// A single permission row from `GET /api/auth/permissions`.
///
/// [name] is the Arabic label shown in the UI. [code] is the unique technical
/// code the backend matches inside `authorize()` (e.g. `TASK_SIGNING`).
/// [type] is the audience: `admin`, `employee`, `citizen`, or the shared
/// `employee,citizen,admin`.
class Permission extends Equatable {
  final int id;
  final String name;
  final String code;
  final String type;

  const Permission({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
  });

  /// The audiences in [type], split on commas (`employee,citizen,admin` → 3).
  List<String> get audiences => type
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// True for permissions granted to more than one audience.
  bool get isShared => audiences.length > 1;

  @override
  List<Object?> get props => [id, name, code, type];
}
