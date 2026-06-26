import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/create_template_usecase.dart';
import '../../domain/usecases/extract_fields_from_upload_usecase.dart';
import '../../domain/usecases/extract_template_fields_usecase.dart';
import '../../domain/usecases/get_templates_usecase.dart';
import '../../domain/usecases/update_template_usecase.dart';
import 'templates_event.dart';
import 'templates_state.dart';

class TemplatesBloc extends Bloc<TemplatesEvent, TemplatesState> {
  final GetTemplatesUseCase getTemplates;
  final CreateTemplateUseCase createTemplate;
  final UpdateTemplateUseCase updateTemplate;
  final ExtractTemplateFieldsUseCase extractFields;
  final ExtractFieldsFromUploadUseCase extractFieldsFromUpload;

  TemplatesBloc({
    required this.getTemplates,
    required this.createTemplate,
    required this.updateTemplate,
    required this.extractFields,
    required this.extractFieldsFromUpload,
  }) : super(const TemplatesState()) {
    on<LoadTemplates>(_onLoad);
    on<ResetTemplateForm>(_onResetForm);
    on<ExtractFromUploadRequested>(_onExtractFromUpload);
    on<CreateTemplateRequested>(_onCreate);
    on<ExtractFieldsRequested>(_onExtractFields);
    on<UpdateTemplateConfigRequested>(_onUpdateConfig);
  }

  Future<void> _onLoad(
    LoadTemplates event,
    Emitter<TemplatesState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, error: null));

    final result = await getTemplates();

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: RequestStatus.success,
        templates: items,
      )),
    );
  }

  void _onResetForm(ResetTemplateForm event, Emitter<TemplatesState> emit) {
    emit(state.copyWith(clearWizard: true));
  }

  /// Create step 1 — upload the picked PDF, extract its fields, and capture the
  /// `path`/`url` the backend assigned. On success the wizard advances to step 2
  /// where these fields are linked and the template is created.
  Future<void> _onExtractFromUpload(
    ExtractFromUploadRequested event,
    Emitter<TemplatesState> emit,
  ) async {
    emit(state.copyWith(
      extractStatus: RequestStatus.loading,
      extractError: null,
    ));

    final result = await extractFieldsFromUpload(
      fileBytes: event.fileBytes,
      fileName: event.fileName,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        extractStatus: RequestStatus.failure,
        extractError: failure.message,
      )),
      (out) => emit(state.copyWith(
        extractStatus: RequestStatus.success,
        extractedFields: out.fields,
        uploadedPath: out.path,
        uploadedUrl: out.url,
      )),
    );
  }

  /// Create step 2 — create the fully-configured template in one call, using the
  /// `path`/`url` captured by [_onExtractFromUpload]. On success it is prepended
  /// to the list.
  Future<void> _onCreate(
    CreateTemplateRequested event,
    Emitter<TemplatesState> emit,
  ) async {
    final path = state.uploadedPath;
    final url = state.uploadedUrl;

    if (path == null || path.isEmpty || url == null || url.isEmpty) {
      emit(state.copyWith(
        createStatus: FormStatus.failure,
        createError: 'ارفع ملف القالب أولاً قبل الحفظ.',
      ));
      return;
    }

    emit(state.copyWith(createStatus: FormStatus.submitting, createError: null));

    final result = await createTemplate(
      name: event.name,
      typeDocId: event.typeDocId,
      path: path,
      url: url,
      config: event.config,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        createStatus: FormStatus.failure,
        createError: failure.message,
      )),
      (created) => emit(state.copyWith(
        createStatus: FormStatus.success,
        createdTemplate: created,
        templates: [created, ...state.templates],
        lastSavedId: created.id,
      )),
    );
  }

  Future<void> _onExtractFields(
    ExtractFieldsRequested event,
    Emitter<TemplatesState> emit,
  ) async {
    await _loadFields(event.id, emit);
  }

  Future<void> _loadFields(int id, Emitter<TemplatesState> emit) async {
    emit(state.copyWith(
      extractStatus: RequestStatus.loading,
      extractError: null,
    ));

    final result = await extractFields(id);

    result.fold(
      (failure) => emit(state.copyWith(
        extractStatus: RequestStatus.failure,
        extractError: failure.message,
      )),
      (fields) => emit(state.copyWith(
        extractStatus: RequestStatus.success,
        extractedFields: fields,
      )),
    );
  }

  /// Step 2 — save `config_json`. On success the backend returns a new version
  /// row; replace the edited template (matched by the old id) with it.
  Future<void> _onUpdateConfig(
    UpdateTemplateConfigRequested event,
    Emitter<TemplatesState> emit,
  ) async {
    emit(state.copyWith(configStatus: FormStatus.submitting, configError: null));

    final result = await updateTemplate(id: event.id, config: event.config);

    result.fold(
      (failure) => emit(state.copyWith(
        configStatus: FormStatus.failure,
        configError: failure.message,
      )),
      (updated) {
        final others =
            state.templates.where((t) => t.id != event.id).toList();
        emit(state.copyWith(
          configStatus: FormStatus.success,
          templates: [updated, ...others],
          lastSavedId: updated.id,
        ));
      },
    );
  }
}
