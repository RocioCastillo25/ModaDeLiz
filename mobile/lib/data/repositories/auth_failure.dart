/// Motivos por los que falla un acceso. No incluyen detalles técnicos.
enum AuthFailureType {
  invalidCredentials,
  accountDisabled,
  incompleteData,
  network,
  server,
}

/// Error tipado que lanzan los repositorios de autenticación.
class AuthFailure implements Exception {
  const AuthFailure(this.type);

  final AuthFailureType type;

  @override
  String toString() => 'AuthFailure(${type.name})';
}
