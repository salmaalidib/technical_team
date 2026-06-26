/// Field-level validation for the two-step template wizard.
///
/// Create flow:
/// * Step 1 — only the uploaded file (the backend extracts its fields first).
/// * Step 2 — name, document type, form_id, form_name, and — since the backend
///   fills each PDF field by `widget.data.id` — every supported extracted PDF
///   field must be linked to a library field before saving.
///
/// Edit flow opens straight on step 2; name/type are fixed (not re-validated).
class Step1Errors {
  final String? file;

  const Step1Errors({this.file});

  bool get isValid => file == null;

  String? get firstMessage => file;
}

/// Create step 1: the file is the only requirement before extraction.
Step1Errors validateStep1({required bool hasFile}) {
  return Step1Errors(file: hasFile ? null : 'ملف القالب مطلوب');
}

class Step2Errors {
  final String? name;
  final String? typeDoc;
  final String? formId;
  final String? formName;

  /// Blocking widget-level problem shown as a snackbar: an unlinked PDF field.
  final String? links;

  const Step2Errors({
    this.name,
    this.typeDoc,
    this.formId,
    this.formName,
    this.links,
  });

  bool get isValid =>
      name == null &&
      typeDoc == null &&
      formId == null &&
      formName == null &&
      links == null;

  String? get firstMessage => name ?? typeDoc ?? formId ?? formName ?? links;
}

/// Step 2 of both flows. [name]/[typeDocId] are validated only on create
/// (pass them as null on edit, where they are not editable).
Step2Errors validateStep2({
  String? name,
  int? typeDocId,
  bool validateMeta = false,
  required String formId,
  required String formName,
  required int supportedFieldCount,
  required int linkedCount,
}) {
  return Step2Errors(
    name: validateMeta && (name == null || name.isEmpty)
        ? 'اسم القالب مطلوب'
        : null,
    typeDoc: validateMeta && typeDocId == null ? 'نوع الوثيقة مطلوب' : null,
    formId: formId.isEmpty ? 'معرّف النموذج مطلوب' : null,
    formName: formName.isEmpty ? 'اسم النموذج مطلوب' : null,
    links: linkedCount < supportedFieldCount
        ? 'يجب ربط جميع حقول الـ PDF بحقل من المكتبة قبل الحفظ'
        : null,
  );
}
