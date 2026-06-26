import '../../domain/entities/extract_fields_result.dart';
import '../../domain/entities/extracted_field.dart';

/// Builds the [ExtractFieldsResult] domain entity from the unwrapped `data`
/// payload of `POST /api/document-templates/extract-fields`
/// (`{ fields, path, url }`).
ExtractFieldsResult extractFieldsResultFromData(dynamic data) {
  final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
  return ExtractFieldsResult(
    fields: ExtractedFieldModel.listFromData(map),
    path: (map['path'] ?? '') as String,
    url: (map['url'] ?? '') as String,
  );
}

/// Parses the `data.fields[]` items returned by
/// `GET /api/document-templates/{id}/fields` and
/// `POST /api/document-templates/extract-fields`:
/// `{ id, pdf_field_type, widget_type }`.
class ExtractedFieldModel extends ExtractedField {
  const ExtractedFieldModel({
    required super.id,
    required super.pdfFieldType,
    required super.widgetType,
  });

  factory ExtractedFieldModel.fromJson(Map<String, dynamic> json) {
    return ExtractedFieldModel(
      id: (json['id'] ?? '') as String,
      pdfFieldType: (json['pdf_field_type'] ?? '') as String,
      widgetType: (json['widget_type'] ?? '') as String,
    );
  }

  /// Reads the `fields` array out of the unwrapped `data` payload.
  static List<ExtractedField> listFromData(dynamic data) {
    final raw = data is Map<String, dynamic> ? data['fields'] : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ExtractedFieldModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
