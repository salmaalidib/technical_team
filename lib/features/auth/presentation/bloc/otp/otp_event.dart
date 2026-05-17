abstract class OtpEvent {}

class OtpSubmitted extends OtpEvent {

  final String sessionId;
  final String otp;

  OtpSubmitted({
    required this.sessionId,
    required this.otp,
  });
}