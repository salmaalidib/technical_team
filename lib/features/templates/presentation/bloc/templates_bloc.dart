import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/create_template_usecase.dart';
import '../../domain/usecases/get_templates_usecase.dart';
import '../../domain/usecases/update_template_usecase.dart';
import 'templates_event.dart';
import 'templates_state.dart';

class TemplatesBloc extends Bloc<TemplatesEvent, TemplatesState> {
  final GetTemplatesUseCase getTemplates;
  final CreateTemplateUseCase createTemplate;
  final UpdateTemplateUseCase updateTemplate;

  TemplatesBloc({
    required this.getTemplates,
    required this.createTemplate,
    required this.updateTemplate,
  }) : super(const TemplatesState()) {
    on<LoadTemplates>(_onLoad);
    on<ResetTemplateForm>(_onResetForm);
    on<CreateTemplateRequested>(_onCreate);
    on<UpdateTemplateRequested>(_onUpdate);
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
    emit(state.copyWith(
      formStatus: FormStatus.idle,
      formError: null,
      clearLastSaved: true,
    ));
  }

  Future<void> _onCreate(
    CreateTemplateRequested event,
    Emitter<TemplatesState> emit,
  ) async {
    emit(state.copyWith(formStatus: FormStatus.submitting, formError: null));

    final result = await createTemplate(
      name: event.name,
      typeDocId: event.typeDocId,
      config: event.config,
      fileBytes: event.fileBytes,
      fileName: event.fileName,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (created) => emit(state.copyWith(
        formStatus: FormStatus.success,
        templates: [created, ...state.templates],
        lastSavedId: created.id,
      )),
    );
  }

  Future<void> _onUpdate(
    UpdateTemplateRequested event,
    Emitter<TemplatesState> emit,
  ) async {
    emit(state.copyWith(formStatus: FormStatus.submitting, formError: null));

    final result = await updateTemplate(
      id: event.id,
      name: event.name,
      typeDocId: event.typeDocId,
      config: event.config,
      fileBytes: event.fileBytes,
      fileName: event.fileName,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (updated) {
        // The backend archives the old version and returns a new row; replace
        // the edited template (matched by the old id) and surface the new one.
        final others =
            state.templates.where((t) => t.id != event.id).toList();
        emit(state.copyWith(
          formStatus: FormStatus.success,
          templates: [updated, ...others],
          lastSavedId: updated.id,
        ));
      },
    );
  }
}
