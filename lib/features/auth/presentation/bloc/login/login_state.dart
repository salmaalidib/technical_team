import '../../../domain/entities/login_response.dart';

class LoginState {

  final bool isLoading;
  final LoginResponse? response;
  final String? error;

  LoginState({
    this.isLoading = false,
    this.response,
    this.error,
  });

  LoginState copyWith({
    bool? isLoading,
    LoginResponse? response,
    String? error,
  }) {

    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      error: error,
    );
  }
}