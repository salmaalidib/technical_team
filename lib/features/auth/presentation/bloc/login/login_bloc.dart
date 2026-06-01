import 'package:flutter_bloc/flutter_bloc.dart';

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

    final result = await loginUseCase(
      userName: event.username,
      password: event.password,
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
