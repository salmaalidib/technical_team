import '../../../process_builder/domain/entities/widget_config.dart';
import '../../domain/entities/form_config.dart';

/// Field-level validation results for the template form. The dynamic fields are
/// picked from the shared field library (already valid per the backend schema),
/// so widget-level checks reduce to "at least one field" and "no duplicate id".
class TemplateFormErrors {
  final String? name;
  final String? typeDoc;
  final String? file;
  final String? formId;
  final String? formName;

  /// A blocking widget-level problem shown as a snackbar (not tied to one
  /// field): no fields selected, or a duplicate widget id across the form.
  final String? widgets;

  const TemplateFormErrors({
    this.name,
    this.typeDoc,
    this.file,
    this.formId,
    this.formName,
    this.widgets,
  });

  bool get isValid =>
      name == null &&
      typeDoc == null &&
      file == null &&
      formId == null &&
      formName == null &&
      widgets == null;

  String? get firstMessage =>
      name ?? typeDoc ?? file ?? formId ?? formName ?? widgets;
}

TemplateFormErrors validateTemplateForm({
  required String name,
  required int? typeDocId,
  required bool hasFile,
  required FormConfig config,
}) {
  return TemplateFormErrors(
    name: name.isEmpty ? 'اسم القالب مطلوب' : null,
    typeDoc: typeDocId == null ? 'نوع الوثيقة مطلوب' : null,
    file: hasFile ? null : 'ملف القالب مطلوب',
    formId: config.formId.isEmpty ? 'معرّف النموذج مطلوب' : null,
    formName: config.formName.isEmpty ? 'اسم النموذج مطلوب' : null,
    widgets: _validateWidgets(config.widgets),
  );
}

String? _validateWidgets(List<WidgetConfig> widgets) {
  if (widgets.isEmpty) return 'أضف حقلاً ديناميكياً واحداً على الأقل للنموذج';

  final seenIds = <String>{};
  for (final w in widgets) {
    if (!seenIds.add(w.widgetId)) {
      return 'حقل مكرّر في النموذج: ${w.label}';
    }
  }
  return null;
}
