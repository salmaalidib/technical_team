import '../../domain/entities/file_picker_entity.dart';

class FilePickerModel extends FilePickerEntity {
  const FilePickerModel({
    required super.id,
    required super.idWidget,
    required super.label,
    required super.isRequired,
    required super.maxSizeMb,
    required super.allowedExtensions,
    required super.allowMultiple,
  });

  factory FilePickerModel.fromJson(Map<String, dynamic> json) {
    final rawExts = json['allowed_extensions'] as List? ?? [];
    final extensions = rawExts.map((e) => e.toString()).toList();

    return FilePickerModel(
      id: json['id'] as int,
      idWidget: (json['id_widget'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      isRequired: (json['is_required'] ?? false) as bool,
      maxSizeMb: (json['max_size_mb'] ?? 1) as int,
      allowedExtensions: extensions,
      allowMultiple: (json['allow_multiple'] ?? false) as bool,
    );
  }
}
