import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/form_status.dart';
import '../../../../core/enums/request_status.dart';
import '../../domain/usecases/get_files_usecase.dart';
import '../../domain/usecases/save_file_usecase.dart';
import 'files_event.dart';
import 'files_state.dart';

class FilesBloc extends Bloc<FilesEvent, FilesState> {
  final GetFilesUseCase getFiles;
  final SaveFileUseCase saveFile;

  FilesBloc({
    required this.getFiles,
    required this.saveFile,
  }) : super(const FilesState()) {
    on<LoadFiles>(_onLoad);
    on<SaveFileRequested>(_onSave);
  }

  Future<void> _onLoad(LoadFiles event, Emitter<FilesState> emit) async {
    emit(state.copyWith(
      status: RequestStatus.loading,
      error: null,
      formStatus: FormStatus.idle,
      formError: null,
    ));

    final result = await getFiles();

    result.fold(
      (failure) => emit(state.copyWith(
        status: RequestStatus.failure,
        error: failure.message,
      )),
      (files) => emit(state.copyWith(
        status: RequestStatus.success,
        files: files,
        error: null,
      )),
    );
  }

  Future<void> _onSave(
    SaveFileRequested event,
    Emitter<FilesState> emit,
  ) async {
    emit(state.copyWith(
      formStatus: FormStatus.submitting,
      formError: null,
    ));

    final result = await saveFile(
      id: event.id,
      name: event.name,
      fileType: event.fileType,
      classification: event.classification,
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        formStatus: FormStatus.failure,
        formError: failure.message,
      )),
      (_) async {
        emit(state.copyWith(formStatus: FormStatus.success));
        add(const LoadFiles());
      },
    );
  }
}
