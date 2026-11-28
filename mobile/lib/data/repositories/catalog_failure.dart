import '../../core/network/api_exception.dart';

/// Motivos de fallo al consultar el catálogo o registrar una venta.
enum CatalogFailureType {
  network,
  server,
  notFound,
  insufficientStock,
  forbidden,
  invalid,
}

/// Error que ven los ViewModels del catálogo. No lleva detalles técnicos.
class CatalogFailure implements Exception {
  const CatalogFailure(this.type);

  final CatalogFailureType type;

  /// Traduce un error de red a un fallo de catálogo según el contrato:
  /// 404 a `notFound`, 409 a `insufficientStock`, 403 a `forbidden`,
  /// 400 a `invalid`, sin conexión a `network` y 5xx a `server`.
  factory CatalogFailure.fromApi(ApiException error) {
    switch (error.kind) {
      case ApiErrorKind.network:
        return const CatalogFailure(CatalogFailureType.network);
      case ApiErrorKind.forbidden:
        return const CatalogFailure(CatalogFailureType.forbidden);
      case ApiErrorKind.badRequest:
        if (error.statusCode == 404) {
          return const CatalogFailure(CatalogFailureType.notFound);
        }
        if (error.statusCode == 409) {
          return const CatalogFailure(CatalogFailureType.insufficientStock);
        }
        return const CatalogFailure(CatalogFailureType.invalid);
      case ApiErrorKind.unauthorized:
      case ApiErrorKind.server:
        return const CatalogFailure(CatalogFailureType.server);
    }
  }

  /// Mensaje en español para el usuario.
  String get message => switch (type) {
    CatalogFailureType.network =>
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
    CatalogFailureType.server =>
      'No pudimos completar la operación. Inténtalo de nuevo.',
    CatalogFailureType.notFound => 'Prenda no encontrada.',
    CatalogFailureType.insufficientStock => 'No hay suficientes piezas.',
    CatalogFailureType.forbidden => 'No tienes permiso para esta acción.',
    CatalogFailureType.invalid =>
      'Revisa los datos e inténtalo de nuevo.',
  };

  @override
  String toString() => 'CatalogFailure(${type.name})';
}
