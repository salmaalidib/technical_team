import '../../../domain/entities/auth_response.dart';

class OtpState {

  final bool isLoading;
  final AuthResponse? response;
  final String? error;



  OtpState({
    this.isLoading = false,
    this.response,
    this.error,
    
  });

  OtpState copyWith({
    bool? isLoading,
    AuthResponse? response,
    String? error,
  }) {

    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      error: error,
    );
  }
}