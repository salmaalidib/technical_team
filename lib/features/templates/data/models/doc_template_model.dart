import 'dart:convert';

import '../../../process_builder/domain/entities/widget_config.dart';
import '../../domain/entities/doc_template.dart';
import '../../domain/entities/form_config.dart';

/// Parses a `document_templates` row (with its joined `type_doc`) into a
/// [DocTemplate]. The `config_json` may arrive either as a decoded map or as a
/// JSON string, so both are handled.
class DocTemplateModel extends DocTemplate {
  const DocTemplateModel({
    required super.id,
    required super.name,
    super.filePath,
    required super.typeDocId,
    super.typeDocName,
    super.engineType,
    super.version,
    super.isLatest,
    super.isActive,
    super.config,
    super.createdAt,
    super.updatedAt,
  });

  factory DocTemplateModel.fromJson(Map<String, dynamic> json) {
    final typeDoc = (json['type_doc'] as Map?)?.cast<String, dynamic>();

    return DocTemplateModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      filePath: json['file_path'] as String?,
      typeDocId: _asInt(json['type_doc_id']) ?? (typeDoc?['id'] as int? ?? 0),
      typeDocName: typeDoc?['name'] as String?,
      engineType: json['engine_type'] as String?,
      version: _asInt(json['version']) ?? 1,
      isLatest: (json['is_latest'] ?? true) as bool,
      isActive: (json['is_active'] ?? true) as bool,
      config: _parseConfig(json['config_json']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static FormConfig? _parseConfig(dynamic raw) {
    if (raw == null) return null;

    Map<String, dynamic>? map;
    if (raw is Map) {
      map = raw.cast<String, dynamic>();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) map = decoded.cast<String, dynamic>();
      } catch (_) {
        return null;
      }
    }
    if (map == null) return null;

    final widgetsRaw = map['widgets'];
    final widgets = widgetsRaw is List
        ? widgetsRaw
            .whereType<Map>()
            .map((w) => WidgetConfig.fromJson(w.cast<String, dynamic>()))
            .toList()
        : <WidgetConfig>[];

    return FormConfig(
      formId: (map['form_id'] ?? '') as String,
      formName: (map['form_name'] ?? '') as String,
      widgets: widgets,
      pdfRaw: (map['pdf'] as Map?)?.cast<String, dynamic>(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
