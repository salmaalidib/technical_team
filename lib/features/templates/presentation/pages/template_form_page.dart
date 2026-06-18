import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/enums/form_status.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../fields/presentation/bloc/fields_bloc.dart';
import '../../../fields/presentation/bloc/fields_event.dart';
import '../../../process_builder/domain/entities/widget_config.dart';
import '../../../type_docs/presentation/bloc/type_docs_bloc.dart';
import '../../../type_docs/presentation/bloc/type_docs_event.dart';
import '../../../type_docs/presentation/widgets/type_doc_selector.dart';
import '../../domain/entities/doc_template.dart';
import '../../domain/entities/form_config.dart';
import '../bloc/templates_bloc.dart';
import '../bloc/templates_event.dart';
import '../bloc/templates_state.dart';
import '../widgets/dynamic_fields_picker.dart';
import '../widgets/form_inputs.dart';
import '../widgets/template_file_upload.dart';
import 'template_validation.dart';

/// Create / edit a document template. Receives the live [TemplatesBloc] from
/// the list page (so the list refreshes in place) and provides a fresh
/// [TypeDocsBloc] for the type pickers.
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
  late final TextEditingController _formIdCtrl;
  late final TextEditingController _formNameCtrl;

  int? _typeDocId;
  PickedFile? _pickedFile;

  /// Dynamic fields linked from the shared library — same model as a stage's
  /// widgets. Keyed by [WidgetConfig.widgetId] for de-dup on toggle.
  late List<WidgetConfig> _widgets;

  TemplateFormErrors _errors = const TemplateFormErrors();

  bool get _isEdit => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    final cfg = t?.config;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _formIdCtrl = TextEditingController(text: cfg?.formId ?? '');
    _formNameCtrl = TextEditingController(text: cfg?.formName ?? '');
    _typeDocId = t?.typeDocId;
    _widgets = List<WidgetConfig>.from(cfg?.widgets ?? const []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _formIdCtrl.dispose();
    _formNameCtrl.dispose();
    super.dispose();
  }

  String? get _existingFileName {
    final path = widget.template?.filePath;
    if (path == null || path.isEmpty) return null;
    return path.split('/').last;
  }

  /// Links / unlinks a library field, mirroring the stage editor's toggle.
  void _toggleWidget(WidgetConfig widget, bool selected) {
    setState(() {
      final next = [..._widgets]
        ..removeWhere((w) => w.widgetId == widget.widgetId);
      if (selected) next.add(widget);
      _widgets = next;
    });
  }

  void _submit() {
    final config = FormConfig(
      formId: _formIdCtrl.text.trim(),
      formName: _formNameCtrl.text.trim(),
      widgets: _widgets,
      pdfRaw: widget.template?.config?.pdfRaw,
    );

    final errors = validateTemplateForm(
      name: _nameCtrl.text.trim(),
      typeDocId: _typeDocId,
      hasFile: _pickedFile != null || (_isEdit && _existingFileName != null),
      config: config,
    );

    setState(() => _errors = errors);

    if (!errors.isValid) {
      AppSnackBar.show(context,
          message: errors.firstMessage ?? 'يرجى تصحيح الأخطاء', isError: true);
      return;
    }

    final bloc = context.read<TemplatesBloc>();
    if (_isEdit) {
      bloc.add(UpdateTemplateRequested(
        id: widget.template!.id,
        name: _nameCtrl.text.trim(),
        typeDocId: _typeDocId!,
        config: config,
        fileBytes: _pickedFile?.bytes,
        fileName: _pickedFile?.name,
      ));
    } else {
      bloc.add(CreateTemplateRequested(
        name: _nameCtrl.text.trim(),
        typeDocId: _typeDocId!,
        config: config,
        fileBytes: _pickedFile!.bytes,
        fileName: _pickedFile!.name,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;

    return BlocConsumer<TemplatesBloc, TemplatesState>(
      listenWhen: (p, c) =>
          p.formStatus != c.formStatus &&
          (c.formStatus == FormStatus.success ||
              c.formStatus == FormStatus.failure),
      listener: (context, state) {
        if (state.formStatus == FormStatus.success) {
          AppSnackBar.show(context,
              message: _isEdit ? 'تم تعديل القالب بنجاح' : 'تم إنشاء القالب بنجاح');
          Navigator.of(context).pop();
        } else if (state.formStatus == FormStatus.failure) {
          AppSnackBar.show(context,
              message: state.formError ?? 'تعذّر حفظ القالب', isError: true);
        }
      },
      builder: (context, state) {
        final submitting = state.formStatus == FormStatus.submitting;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            color: const Color(0xffF0EFE7),
            child: SafeArea(
              child: Column(
                children: [
                  _Header(
                    title: _isEdit ? 'تعديل قالب وثيقة' : 'قالب وثيقة جديد',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          horizontal, 8, horizontal, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Section(
                                title: 'بيانات القالب',
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LabeledField(
                                      label: 'اسم القالب',
                                      controller: _nameCtrl,
                                      hint: 'استمارة معاملة المواطن',
                                      errorText: _errors.name,
                                    ),
                                    const SizedBox(height: 16),
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(bottom: 6, right: 2),
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
                                      onChanged: (id) =>
                                          setState(() => _typeDocId = id),
                                      errorText: _errors.typeDoc,
                                    ),
                                    const SizedBox(height: 16),
                                    TemplateFileUpload(
                                      picked: _pickedFile,
                                      existingFileName: _existingFileName,
                                      onPicked: (f) =>
                                          setState(() => _pickedFile = f),
                                      onCleared: () =>
                                          setState(() => _pickedFile = null),
                                      errorText: _errors.file,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _Section(
                                title: 'إعدادات النموذج',
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: LabeledField(
                                        label: 'معرّف النموذج (form_id)',
                                        controller: _formIdCtrl,
                                        hint: 'civil_transaction_55',
                                        errorText: _errors.formId,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: LabeledField(
                                        label: 'اسم النموذج (form_name)',
                                        controller: _formNameCtrl,
                                        hint: 'استمارة معاملة المواطن',
                                        errorText: _errors.formName,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _Section(
                                title: 'الحقول الديناميكية',
                                child: DynamicFieldsPicker(
                                  selected: _widgets,
                                  onToggle: _toggleWidget,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: submitting ? null : _submit,
                                  child: submitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(_isEdit
                                          ? 'حفظ التعديلات'
                                          : 'إنشاء القالب'),
                                ),
                              ),
                            ],
                          ),
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
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_rounded,
                color: AppColors.textPrimary),
            tooltip: 'رجوع',
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
