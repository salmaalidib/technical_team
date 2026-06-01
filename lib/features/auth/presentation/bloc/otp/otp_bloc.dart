import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/verify_otp_usecase.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final VerifyOtpUseCase useCase;

  OtpBloc(this.useCase) : super(OtpState()) {
    on<OtpSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(
    OtpSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    // Token persistence now happens inside the repository, so the bloc only
    // maps the Either result to UI state — no storage, no try/catch.
    final result = await useCase(
      sessionId: event.sessionId,
      otp: event.otp,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (response) => emit(state.copyWith(
        isLoading: false,
        response: response,
      )),
    );
  }
}
