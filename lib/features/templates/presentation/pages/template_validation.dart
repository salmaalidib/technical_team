/// Field-level validation for the two-step template wizard.
///
/// * Step 1 (create): name, document type, uploaded file.
/// * Step 2 (config): form_id, form_name, and — since the backend fills each
///   PDF field by `widget.data.id` — every supported extracted PDF field must
///   be linked to a library field before saving.
class Step1Errors {
  final String? name;
  final String? typeDoc;
  final String? file;

  const Step1Errors({this.name, this.typeDoc, this.file});

  bool get isValid => name == null && typeDoc == null && file == null;

  String? get firstMessage => name ?? typeDoc ?? file;
}

Step1Errors validateStep1({
  required String name,
  required int? typeDocId,
  required bool hasFile,
}) {
  return Step1Errors(
    name: name.isEmpty ? 'اسم القالب مطلوب' : null,
    typeDoc: typeDocId == null ? 'نوع الوثيقة مطلوب' : null,
    file: hasFile ? null : 'ملف القالب مطلوب',
  );
}

class Step2Errors {
  final String? formId;
  final String? formName;

  /// Blocking widget-level problem shown as a snackbar: an unlinked PDF field.
  final String? links;

  const Step2Errors({this.formId, this.formName, this.links});

  bool get isValid => formId == null && formName == null && links == null;

  String? get firstMessage => formId ?? formName ?? links;
}

Step2Errors validateStep2({
  required String formId,
  required String formName,
  required int supportedFieldCount,
  required int linkedCount,
}) {
  return Step2Errors(
    formId: formId.isEmpty ? 'معرّف النموذج مطلوب' : null,
    formName: formName.isEmpty ? 'اسم النموذج مطلوب' : null,
    links: linkedCount < supportedFieldCount
        ? 'يجب ربط جميع حقول الـ PDF بحقل من المكتبة قبل الحفظ'
        : null,
  );
}
