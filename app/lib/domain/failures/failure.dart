import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [runtimeType, message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Could not reach the server.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'The server returned an error.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Aircraft not found.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
