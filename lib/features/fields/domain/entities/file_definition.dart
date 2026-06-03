import 'package:equatable/equatable.dart';

/// A reusable file definition as returned by `GET /api/files`.
///
/// This is a *definition* of a requestable file type (not an uploaded file).
/// [classification] maps to the backend `type` enum.
class FileDefinition extends Equatable {
  final int id;
  final String fileName;
  final String fileType;
  final String classification;
  final String? createdAt;
  final String? updatedAt;

  const FileDefinition({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.classification,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props =>
      [id, fileName, fileType, classification, createdAt, updatedAt];
}
