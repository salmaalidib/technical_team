import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/entities/type_doc.dart';
import '../../domain/usecases/create_type_doc_usecase.dart';
import '../../domain/usecases/get_type_docs_usecase.dart';
import '../../domain/usecases/update_type_doc_usecase.dart';
import 'type_docs_event.dart';
import 'type_docs_state.dart';

class TypeDocsBloc extends Bloc<TypeDocsEvent, TypeDocsState> {
  final GetTypeDocsUseCase getTypeDocs;
  final CreateTypeDocUseCase createTypeDoc;
  final UpdateTypeDocUseCase updateTypeDoc;

  TypeDocsBloc({
    required this.getTypeDocs,
    required this.createTypeDoc,
    required this.updateTypeDoc,
  }) : super(const TypeDocsState()) {
    on<LoadTypeDocs>(_onLoad);
    on<CreateTypeDocRequested>(_onCreate);
    on<RenameTypeDocRequested>(_onRename);
    on<DeactivateTypeDocRequested>(_onDeactivate);
  }

  Future<void> _onLoad(
    LoadTypeDocs event,
    Emitter<TypeDocsState> emit,
  ) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));

    final result = await getTypeDocs();

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: RequestStatus.success,
        typeDocs: items,
        error: null,
      )),
    );
  }

  Future<void> _onCreate(
    CreateTypeDocRequested event,
    Emitter<TypeDocsState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await createTypeDoc(name: event.name);

    result.fold(
      (failure) => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (created) => emit(state.copyWith(
        formStatus: FormStatus.success,
        typeDocs: [...state.typeDocs, created],
        lastCreatedId: created.id,
      )),
    );
  }

  Future<void> _onRename(
    RenameTypeDocRequested event,
    Emitter<TypeDocsState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await updateTypeDoc(id: event.id, name: event.name);

    result.fold(
      (failure) => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (updated) => emit(state.copyWith(
        formStatus: FormStatus.success,
        typeDocs: _replace(updated),
      )),
    );
  }

  Future<void> _onDeactivate(
    DeactivateTypeDocRequested event,
    Emitter<TypeDocsState> emit,
  ) async {
    emit(state.copyWith(
      busyIds: {...state.busyIds, event.id},
      actionError: null,
    ));

    final result = await updateTypeDoc(id: event.id, isActive: false);

    final busy = {...state.busyIds}..remove(event.id);

    result.fold(
      (failure) => emit(state.copyWith(
        busyIds: busy,
        actionError: failure.message,
      )),
      (updated) => emit(state.copyWith(
        typeDocs: _replace(updated),
        busyIds: busy,
      )),
    );
  }

  List<TypeDoc> _replace(TypeDoc updated) => state.typeDocs
      .map((t) => t.id == updated.id ? updated : t)
      .toList();
}
