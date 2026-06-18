import 'package:equatable/equatable.dart';

import 'form_config.dart';

/// A document template as returned by `GET /api/document-templates` — one row
/// of the `document_templates` table joined with its `type_doc`.
///
/// Updates are versioned on the backend: a `PUT` archives the old row
/// (`is_active = false`) and creates a new one with `version + 1`, so the list
/// always shows the latest active version.
class DocTemplate extends Equatable {
  final int id;
  final String name;
  final String? filePath;
  final int typeDocId;
  final String? typeDocName;
  final String? engineType;
  final int version;
  final bool isLatest;
  final bool isActive;
  final FormConfig? config;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocTemplate({
    required this.id,
    required this.name,
    this.filePath,
    required this.typeDocId,
    this.typeDocName,
    this.engineType,
    this.version = 1,
    this.isLatest = true,
    this.isActive = true,
    this.config,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        filePath,
        typeDocId,
        typeDocName,
        engineType,
        version,
        isLatest,
        isActive,
        config,
        createdAt,
        updatedAt,
      ];
}
