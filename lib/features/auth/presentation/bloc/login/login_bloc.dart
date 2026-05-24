import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:technical_team/core/errors/failures.dart';
import '../../../domain/usecases/login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;

  LoginBloc(this.loginUseCase) : super(LoginState()) {
    on<LoginSubmitted>(_onLogin);
  }

Future<void> _onLogin(
  LoginSubmitted event,
  Emitter<LoginState> emit,
) async {

  emit(state.copyWith(isLoading: true));

  try {

    final response = await loginUseCase(
      userName: event.username,
      password: event.password,
    );

    emit(state.copyWith(
      isLoading: false,
      response: response,
    ));

 } catch (e) {
  String errorMessage = ErrorHandler.handle(e);

  if (e is DioException) {
    final data = e.response?.data;

    if (data is Map && data["message"] != null) {
      errorMessage = data["message"].toString();
    }
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
