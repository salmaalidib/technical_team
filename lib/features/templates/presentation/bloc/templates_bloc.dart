import 'dart:async';

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

/// Page size used by the templates list screen (infinite scroll) and by the
/// wizard's searchable template dropdown.
const int kTemplatesPageSize = 10;

/// Page size for callers that need every template at once — the wizard picker
/// must render templates already linked to a stage even when they fall on a
/// later page.
const int kTemplatesAllPageSize = 70;

const Duration _kSearchDebounce = Duration(milliseconds: 350);

/// Restartable debounce: each new event cancels the pending one. Mirrors the
/// transformer in `FieldsBloc` so both dropdowns feel identical.
EventTransformer<E> _debounceRestartable<E>(Duration duration) {
  return (events, mapper) {
    return events
        .transform(_DebounceStreamTransformer<E>(duration))
        .asyncExpand(mapper);
  };
}

class _DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  const _DebounceStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    Timer? timer;
    late StreamController<T> controller;

    controller = StreamController<T>(
      onListen: () {
        final sub = stream.listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () => controller.add(data));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
        controller.onCancel = () {
          timer?.cancel();
          return sub.cancel();
        };
      },
    );

    return controller.stream;
  }
}

class TemplatesBloc extends Bloc<TemplatesEvent, TemplatesState> {
  final GetTemplatesUseCase getTemplates;
  final CreateTemplateUseCase createTemplate;
  final UpdateTemplateUseCase updateTemplate;
  final ExtractTemplateFieldsUseCase extractFields;
  final ExtractFieldsFromUploadUseCase extractFieldsFromUpload;

  /// Page size for this bloc instance — set by [LoadTemplates.limit] so the
  /// wizard picker and the list screen can use different sizes.
  int _pageLimit;

  TemplatesBloc({
    required this.getTemplates,
    required this.createTemplate,
    required this.updateTemplate,
    required this.extractFields,
    required this.extractFieldsFromUpload,
  })  : _pageLimit = kTemplatesPageSize,
        super(const TemplatesState()) {
    on<LoadTemplates>(_onLoad);
    on<TemplatesSearchChanged>(
      _onSearchChanged,
      transformer: _debounceRestartable(_kSearchDebounce),
    );
    on<TemplatesNextPageRequested>(_onNextPage);
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
    _pageLimit = event.limit;
    await _loadFirstPage('', emit);
  }

  Future<void> _onSearchChanged(
    TemplatesSearchChanged event,
    Emitter<TemplatesState> emit,
  ) async {
    await _loadFirstPage(event.query.trim(), emit);
  }

  /// Loads page 1 with [search], replacing the accumulated items.
  Future<void> _loadFirstPage(
    String search,
    Emitter<TemplatesState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      search: search,
      loadingMore: false,
    ));

    final result = await getTemplates(
      page: 1,
      limit: _pageLimit,
      search: search.isEmpty ? null : search,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: RequestStatus.success,
        templates: page.items,
        meta: page.meta,
        error: null,
      )),
    );
  }

  Future<void> _onNextPage(
    TemplatesNextPageRequested event,
    Emitter<TemplatesState> emit,
  ) async {
    if (state.loadingMore ||
        state.status == RequestStatus.loading ||
        !state.hasMore) {
      return;
    }

    emit(state.copyWith(loadingMore: true, error: null));

    final result = await getTemplates(
      page: state.nextPage,
      limit: _pageLimit,
      search: state.search.isEmpty ? null : state.search,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        loadingMore: false,
        error: failure.message,
      )),
      (page) {
        // Guard against a page arriving twice (double-fire, or a reload racing
        // the append): keep only ids not already held.
        final seen = state.templates.map((t) => t.id).toSet();
        final fresh = page.items.where((t) => seen.add(t.id)).toList();

        emit(state.copyWith(
          loadingMore: false,
          templates: [...state.templates, ...fresh],
          meta: page.meta,
          error: null,
        ));
      },
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
