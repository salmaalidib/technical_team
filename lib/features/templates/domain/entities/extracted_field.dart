import 'package:equatable/equatable.dart';

/// One AcroForm field read out of a template's PDF by the backend
/// (`GET /api/document-templates/{id}/fields`).
///
/// [id] is the **internal PDF field name** (e.g. `employee`, `manager-name`) —
/// this is what a `config_json.widgets[i].data.id` must equal so the backend
/// can fill that field at PDF-generation time. [widgetType] is the backend's
/// best guess of the matching widget (`text_field`, `dropdown`, ...).
class ExtractedField extends Equatable {
  final String id;
  final String pdfFieldType;
  final String widgetType;

  const ExtractedField({
    required this.id,
    required this.pdfFieldType,
    required this.widgetType,
  });

  @override
  List<Object?> get props => [id, pdfFieldType, widgetType];
}
