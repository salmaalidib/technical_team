import 'package:equatable/equatable.dart';

/// Base type for every recoverable error that crosses a layer boundary.
///
/// All network/error mapping happens once inside `ApiService`; the result is
/// surfaced on the `Left` side of `Either<Failure, T>` and carries a
/// ready-to-display Arabic [message]. Presentation layers only read
/// `failure.message` — they never inspect Dio or status codes.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server-side or unexpected response error (4xx/5xx, malformed payload).
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Connectivity / timeout error — the request never reached a usable response.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Authentication / authorization error (401/403) after the interceptor has
/// already had its chance to refresh the access token.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
