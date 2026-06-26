import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../fields/presentation/bloc/fields_bloc.dart';
import '../../../fields/presentation/bloc/fields_event.dart';
import '../../../process_builder/domain/entities/widget_config.dart';
import '../../../type_docs/presentation/bloc/type_docs_bloc.dart';
import '../../../type_docs/presentation/bloc/type_docs_event.dart';
import '../../../type_docs/presentation/widgets/type_doc_selector.dart';
import '../../domain/entities/doc_template.dart';
import '../../domain/entities/extracted_field.dart';
import '../../domain/entities/form_config.dart';
import '../bloc/templates_bloc.dart';
import '../bloc/templates_event.dart';
import '../bloc/templates_state.dart';
import '../widgets/extracted_fields_picker.dart';
import '../widgets/form_inputs.dart';
import '../widgets/template_file_upload.dart';
import 'template_validation.dart';

/// Create / edit a document template as a **two-step wizard** that mirrors the
/// backend API:
///   * Step 1 (create) — upload the PDF (`POST /extract-fields`); the backend
///     returns its AcroForm fields + the stored file's path/url.
///   * Step 2 (create) — enter name + type + form metadata, link each extracted
///     field to a library field, then create the template in one JSON call
///     (`POST /` with name + type + path + url + config_json).
///
/// On edit the form opens straight on step 2 for the existing template (its
/// name / type / file are not editable — only `config_json` via `PUT /{id}`).
class TemplateFormPage extends StatelessWidget {
  final TemplatesBloc templatesBloc;
  final DocTemplate? template; // null = create

  const TemplateFormPage({
    super.key,
    required this.templatesBloc,
    this.template,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: templatesBloc),
        BlocProvider(
          create: (_) => getIt<TypeDocsBloc>()..add(const LoadTypeDocs()),
        ),
        // Field library for the dynamic-fields picker (same source the stage
        // customization step uses).
        BlocProvider(
          create: (_) => getIt<FieldsBloc>()..add(const LoadAllFields()),
        ),
      ],
      child: _TemplateFormView(template: template),
    );
  }
}

class _TemplateFormView extends StatefulWidget {
  final DocTemplate? template;

  const _TemplateFormView({this.template});

  @override
  State<_TemplateFormView> createState() => _TemplateFormViewState();
}

class _TemplateFormViewState extends State<_TemplateFormView> {
  late final TextEditingController _nameCtrl;

  int? _typeDocId;
  PickedFile? _pickedFile;

  /// Wizard position: 1 = basic info (create), 2 = config (link + save).
  late int _step;

  /// The template id once it exists (created in step 1, or the edited one).
  int? _templateId;

  /// PDF-field-id → linked widget (`data.id` forced to the PDF field id).
  final Map<String, WidgetConfig?> _links = {};

  /// On edit, the saved `form_id`/`form_name` are preserved as-is (the name is
  /// not editable). On create they are derived from the template name — see
  /// [_formId] / [_formName].
  String? _existingFormId;
  String? _existingFormName;

  bool get _isEdit => widget.template != null;

  /// `form_id` sent to the backend: the saved one on edit, otherwise the
  /// template name (capped at the backend's 128-char limit).
  String get _formId {
    if (_isEdit && (_existingFormId?.isNotEmpty ?? false)) {
      return _existingFormId!;
    }
    final name = _nameCtrl.text.trim();
    return name.length > 128 ? name.substring(0, 128) : name;
  }

  /// `form_name` sent to the backend: the saved one on edit, otherwise the
  /// template name.
  String get _formName => _isEdit && (_existingFormName?.isNotEmpty ?? false)
      ? _existingFormName!
      : _nameCtrl.text.trim();

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    final cfg = t?.config;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _existingFormId = cfg?.formId;
    _existingFormName = cfg?.formName;
    _typeDocId = t?.typeDocId;

    if (_isEdit) {
      // Edit: jump straight to step 2 for the existing template.
      _step = 2;
      _templateId = t!.id;
      // Pre-seed links from the saved config so already-mapped fields show up.
      for (final w in cfg?.widgets ?? const <WidgetConfig>[]) {
        final pdfId = (w.data['id'] ?? '') as String;
        if (pdfId.isNotEmpty) _links[pdfId] = w;
      }
      // Load the template's extracted PDF fields.
      context.read<TemplatesBloc>().add(ExtractFieldsRequested(t.id));
    } else {
      _step = 1;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? get _existingFileName {
    final path = widget.template?.filePath;
    if (path == null || path.isEmpty) return null;
    return path.split('/').last;
  }

  // ────────────── step 1 (create): upload + extract fields ──────────────
  void _submitStep1() {
    final errors = validateStep1(hasFile: _pickedFile != null);
    if (!errors.isValid) {
      AppSnackBar.show(context,
          message: errors.firstMessage ?? 'يرجى تصحيح الأخطاء', isError: true);
      return;
    }

    context.read<TemplatesBloc>().add(ExtractFromUploadRequested(
          fileBytes: _pickedFile!.bytes,
          fileName: _pickedFile!.name,
        ));
  }

  // ──────────── step 2: link fields, then create / save config ────────────
  void _submitStep2(List<ExtractedField> extractedFields) {
    final supported = ExtractedFieldsPicker.supportedFields(extractedFields);
    final linkedWidgets =
        _links.values.whereType<WidgetConfig>().toList(growable: false);

    final errors = validateStep2(
      name: _nameCtrl.text.trim(),
      typeDocId: _typeDocId,
      validateMeta: !_isEdit, // name/type only required on create
      // form_id / form_name are derived from the name, not entered — always
      // valid once the name passes [validateMeta].
      formId: _formId,
      formName: _formName,
      supportedFieldCount: supported.length,
      linkedCount: linkedWidgets.length,
    );
    if (!errors.isValid) {
      AppSnackBar.show(context,
          message: errors.firstMessage ?? 'يرجى تصحيح الأخطاء', isError: true);
      return;
    }

    final config = FormConfig(
      formId: _formId,
      formName: _formName,
      widgets: linkedWidgets,
      pdfRaw: widget.template?.config?.pdfRaw,
    );

    final bloc = context.read<TemplatesBloc>();
    if (_isEdit) {
      bloc.add(UpdateTemplateConfigRequested(id: _templateId!, config: config));
    } else {
      bloc.add(CreateTemplateRequested(
        name: _nameCtrl.text.trim(),
        typeDocId: _typeDocId!,
        config: config,
      ));
    }
  }

  void _onLink(ExtractedField pdfField, WidgetConfig? widget) {
    setState(() {
      if (widget == null) {
        _links.remove(pdfField.id);
      } else {
        _links[pdfField.id] = widget;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    return BlocConsumer<TemplatesBloc, TemplatesState>(
      listenWhen: (p, c) =>
          p.extractStatus != c.extractStatus ||
          p.createStatus != c.createStatus ||
          p.configStatus != c.configStatus,
      listener: (context, state) {
        // Step 1 (create) — upload + extract finished: advance to step 2.
        if (!_isEdit && _step == 1) {
          if (state.extractStatus == RequestStatus.success) {
            setState(() => _step = 2);
            AppSnackBar.show(context,
                message: 'تم رفع الملف — أكمل بيانات القالب وربط الحقول');
          } else if (state.extractStatus == RequestStatus.failure) {
            AppSnackBar.show(context,
                message: state.extractError ?? 'تعذّر رفع الملف واستخراج الحقول',
                isError: true);
          }
        }

        // Step 2 (create) — the single create call finished.
        if (state.createStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم حفظ القالب بنجاح');
          Navigator.of(context).pop();
        } else if (state.createStatus == FormStatus.failure) {
          AppSnackBar.show(context,
              message: state.createError ?? 'تعذّر إنشاء القالب', isError: true);
        }

        // Step 2 (edit) — config save finished.
        if (state.configStatus == FormStatus.success) {
          AppSnackBar.show(context, message: 'تم تعديل القالب بنجاح');
          Navigator.of(context).pop();
        } else if (state.configStatus == FormStatus.failure) {
          AppSnackBar.show(context,
              message: state.configError ?? 'تعذّر حفظ إعدادات القالب',
              isError: true);
        }
      },
      builder: (context, state) {
        final submitting = _step == 1
            ? state.extractStatus == RequestStatus.loading
            : (state.createStatus == FormStatus.submitting ||
                state.configStatus == FormStatus.submitting);

        // Nothing is persisted until the final submit, so leaving is always
        // safe — no back-navigation guard needed.
        return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              color: const Color(0xffF0EFE7),
              child: SafeArea(
                child: Column(
                  children: [
                    _Header(
                      title: _isEdit ? 'تعديل قالب وثيقة' : 'قالب وثيقة جديد',
                      step: _step,
                      canBack: true,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            EdgeInsets.fromLTRB(horizontal, 8, horizontal, 28),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: _step == 1
                                ? _buildStep1(submitting)
                                : _buildStep2(context, state, submitting),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _buildStep1(bool submitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: 'ملف القالب',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12, right: 2),
                child: Text(
                  'ارفع ملف الـ PDF لاستخراج حقوله، ثم أكمل بياناته في الخطوة '
                  'التالية.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              TemplateFileUpload(
                picked: _pickedFile,
                existingFileName: _existingFileName,
                onPicked: (f) => setState(() => _pickedFile = f),
                onCleared: () => setState(() => _pickedFile = null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'رفع واستخراج الحقول',
          icon: Icons.arrow_back_rounded,
          submitting: submitting,
          onPressed: _submitStep1,
        ),
      ],
    );
  }

  Widget _buildStep2(
    BuildContext context,
    TemplatesState state,
    bool submitting,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name + document type — only entered on create; on edit they are fixed
        // by the backend and the section is omitted.
        if (!_isEdit) ...[
          _Section(
            title: 'بيانات القالب',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: 'اسم القالب',
                  controller: _nameCtrl,
                  hint: 'استمارة معاملة المواطن',
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6, right: 2),
                  child: Text(
                    'نوع الوثيقة',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TypeDocSelector(
                  value: _typeDocId,
                  onChanged: (id) => setState(() => _typeDocId = id),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        _Section(
          title: 'ربط حقول الـ PDF',
          child: _Step2Fields(
            state: state,
            links: _links,
            onLink: _onLink,
            // Re-extract only applies to the edit flow (by saved-template id).
            // On create, an extract failure keeps the user on step 1.
            retryTemplateId: _isEdit ? _templateId : null,
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'حفظ القالب',
          icon: Icons.check_rounded,
          submitting: submitting,
          onPressed: state.extractStatus == RequestStatus.success
              ? () => _submitStep2(state.extractedFields)
              : null,
        ),
      ],
    );
  }
}

/// Renders the extract-fields load states and, on success, the linking cards.
class _Step2Fields extends StatelessWidget {
  final TemplatesState state;
  final Map<String, WidgetConfig?> links;
  final void Function(ExtractedField pdfField, WidgetConfig? widget) onLink;

  /// The saved template id to re-extract from on retry — set only on the edit
  /// flow. Null on create (where retry is not offered here).
  final int? retryTemplateId;

  const _Step2Fields({
    required this.state,
    required this.links,
    required this.onLink,
    required this.retryTemplateId,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.extractStatus) {
      case RequestStatus.initial:
      case RequestStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      case RequestStatus.failure:
        return Column(
          children: [
            Text(
              state.extractError ?? 'تعذّر استخراج حقول الـ PDF',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (retryTemplateId != null)
              OutlinedButton.icon(
                onPressed: () => context
                    .read<TemplatesBloc>()
                    .add(ExtractFieldsRequested(retryTemplateId!)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
          ],
        );
      case RequestStatus.success:
        return ExtractedFieldsPicker(
          fields: state.extractedFields,
          links: links,
          onLink: onLink,
        );
    }
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int step;
  final bool canBack;
  final VoidCallback onBack;

  const _Header({
    required this.title,
    required this.step,
    required this.canBack,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          if (canBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.textPrimary),
              tooltip: 'رجوع',
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepBadge(step: step),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int step;
  const _StepBadge({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'الخطوة $step من 2',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool submitting;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.submitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: submitting ? null : onPressed,
        icon: submitting
            ? const SizedBox.shrink()
            : Icon(icon, size: 20),
        label: submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
