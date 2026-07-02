import 'package:equatable/equatable.dart';

import '../../domain/entities/field_type.dart';

abstract class FieldsEvent extends Equatable {
  const FieldsEvent();

  @override
  List<Object?> get props => [];
}

/// Ensures [type]'s first page is loaded (no-op if already loaded and not
/// forced). Fired when a dropdown of that type first opens.
class FieldTypeOpened extends FieldsEvent {
  final FieldType type;
  final bool forceReload;

  const FieldTypeOpened(this.type, {this.forceReload = false});

  @override
  List<Object?> get props => [type, forceReload];
}

/// The user typed in a type's search box. Debounced in the bloc; resets to
/// page 1 with the new [query].
class FieldTypeSearchChanged extends FieldsEvent {
  final FieldType type;
  final String query;

  const FieldTypeSearchChanged(this.type, this.query);

  @override
  List<Object?> get props => [type, query];
}

/// Requests the next page for [type] (infinite scroll). Ignored when there is
/// no next page or a load is already running.
class FieldTypeNextPageRequested extends FieldsEvent {
  final FieldType type;

  const FieldTypeNextPageRequested(this.type);

  @override
  List<Object?> get props => [type];
}

/// Creates a new field of [type] from [body]; on success reloads that type's
/// first page (respecting the current search).
class CreateFieldRequested extends FieldsEvent {
  final FieldType type;
  final Map<String, dynamic> body;

  const CreateFieldRequested({required this.type, required this.body});

  @override
  List<Object?> get props => [type, body];
}
