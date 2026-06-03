import '../../domain/entities/file_definition.dart';

class FileDefinitionModel extends FileDefinition {
  const FileDefinitionModel({
    required super.id,
    required super.fileName,
    required super.fileType,
    required super.classification,
    super.createdAt,
    super.updatedAt,
  });

  factory FileDefinitionModel.fromJson(Map<String, dynamic> json) {
    return FileDefinitionModel(
      id: json['id'] as int,
      fileName: (json['file_name'] ?? '') as String,
      fileType: (json['file_type'] ?? '') as String,
      classification: (json['type'] ?? '') as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
