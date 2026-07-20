import 'failure.dart';

class RepositoryException implements Exception {
  const RepositoryException(this.failure);

  final Failure failure;

  @override
  String toString() =>
      'RepositoryException(${failure.runtimeType}: ${failure.message})';
}
