import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:technical_team/core/storage/secure_storage_service.dart';

import '../../../domain/usecases/verify_otp_usecase.dart';
import 'package:dio/dio.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {

  final VerifyOtpUseCase useCase;
  final SecureStorageService storage;

  OtpBloc(this.useCase, this.storage) : super(OtpState()) {

    on<OtpSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(
    OtpSubmitted event,
    Emitter<OtpState> emit,
  ) async {

    emit(state.copyWith(isLoading: true));

    try {

final response = await useCase(
  sessionId: event.sessionId,
  otp: event.otp,
);

await storage.saveToken(response.token);


      emit(state.copyWith(
        isLoading: false,
        response: response,
      ));

   } catch (e) {

  print("OTP ERROR: $e");

  String errorMessage = "حدث خطأ غير متوقع";

  if (e is DioException) {

   errorMessage =
    e.response?.data["message"]?.toString() ??
    "حدث خطأ أثناء التحقق";
  }

  emit(
    state.copyWith(
      isLoading: false,
      error: errorMessage,
    ),
  );
}
  }
}