import 'package:equatable/equatable.dart';

import '../../../process_builder/domain/entities/widget_config.dart';

/// The parsed `config_json` of a document template: the form metadata plus its
/// ordered list of widgets.
///
/// Widgets are modeled with [WidgetConfig] — the same entity the stage-config
/// flow uses — so a template's dynamic fields are picked from the shared field
/// library exactly like a stage's, and serialize to the identical
/// `{ widget_type, data }` shape the backend expects.
///
/// The optional `pdf` rendering block returned by the backend is preserved
/// verbatim in [pdfRaw] so an update round-trips it untouched.
class FormConfig extends Equatable {
  final String formId;
  final String formName;
  final List<WidgetConfig> widgets;
  final Map<String, dynamic>? pdfRaw;

  const FormConfig({
    required this.formId,
    required this.formName,
    this.widgets = const [],
    this.pdfRaw,
  });

  FormConfig copyWith({
    String? formId,
    String? formName,
    List<WidgetConfig>? widgets,
    Map<String, dynamic>? pdfRaw,
  }) {
    return FormConfig(
      formId: formId ?? this.formId,
      formName: formName ?? this.formName,
      widgets: widgets ?? this.widgets,
      pdfRaw: pdfRaw ?? this.pdfRaw,
    );
  }

  /// Serializes to the exact shape the backend `config_json` expects.
  Map<String, dynamic> toJson() => {
        'form_id': formId,
        'form_name': formName,
        'widgets': widgets.map((w) => w.toJson()).toList(),
        if (pdfRaw != null) 'pdf': pdfRaw,
      };

  @override
  List<Object?> get props => [formId, formName, widgets, pdfRaw];
}
