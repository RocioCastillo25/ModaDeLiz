# Interfaces internas: Consulta de inventario, escáner y venta

Contratos entre capas de la app. Cada interfaz tiene implementación real y simulada, intercambiables en `core/di/service_locator.dart`.

## PrendaRepository

```dart
abstract class PrendaRepository {
  /// Busca prendas con los filtros dados. Lanza [CatalogFailure].
  Future<List<Prenda>> search(SearchFilters filters);

  /// Ficha con las existencias de las 5 sucursales. Lanza [CatalogFailure]
  /// (`notFound` si no existe).
  Future<PrendaFicha> getById(int id);

  /// Ficha a partir del código de barras. Lanza [CatalogFailure]
  /// (`notFound` si el código no corresponde a ninguna prenda).
  Future<PrendaFicha> getByBarcode(String barcode);
}
```

Real: `ApiPrendaRepository` (usa `CatalogService`). Simulada: `MockPrendaRepository` con prendas de varias sucursales, tallas y colores, y casos de existencia baja y agotada.

## InventarioRepository

```dart
abstract class InventarioRepository {
  /// Descuenta [quantity] piezas de la existencia [stockId]. Devuelve la
  /// existencia que informa la API. Lanza [CatalogFailure]:
  /// `insufficientStock`, `forbidden`, `invalid`, `network`, `server`.
  Future<StockItem> sell(int stockId, int quantity);
}
```

Real: `ApiInventarioRepository`. Simulada: `MockInventarioRepository`, que descuenta en memoria y rechaza con `insufficientStock` cuando no alcanza.

## BranchRepository

```dart
abstract class BranchRepository {
  Future<List<Branch>> list();
}
```

## BarcodeScannerService (Adapter sobre `mobile_scanner`)

```dart
abstract class BarcodeScannerService {
  /// Códigos leídos, ya sin repeticiones consecutivas del mismo valor.
  Stream<String> get codes;

  /// Inicia la cámara. Si el sistema lo pide, muestra la solicitud de permiso.
  /// Lanza [ScannerException] con [ScannerError.permissionDenied] o
  /// [ScannerError.unavailable].
  Future<void> start();

  Future<void> stop();

  /// Enciende o apaga la linterna. No hace nada si el dispositivo no la tiene.
  Future<void> toggleTorch();

  /// Vista previa de la cámara, para incrustar en la pantalla del escáner.
  /// Es la única forma en que las pantallas ven la cámara.
  Widget buildPreview();

  Future<void> dispose();
}
```

Implementación real: `MobileScannerService`, el único archivo que importa `mobile_scanner`. Simulada: `FakeBarcodeScannerService` para pruebas, con un `StreamController` y control de errores.

## ViewModels (sin importar `material.dart`)

| ViewModel | Estado | Acciones |
|-----------|--------|----------|
| `BusquedaViewModel` | `idle`, `loading`, `results`, `empty`, `error`; filtros; sucursales | `search()`, `applyFilters()`, `clearFilters()`, `loadMore()`, `retry()` |
| `FichaViewModel` | `loading`, `data`, `error`; ficha; existencia propia | `load(id)`, `loadByBarcode(code)`, `refresh()`, `applySale(StockItem)` |
| `VentaViewModel` | `editing`, `confirming`, `submitting`, `done`, `error`; cantidad | `setQuantity(text)`, `confirm()`, `submit()`; valida entero positivo y bloquea el doble envío y la falta de conexión |
| `EscanerViewModel` | `explaining`, `scanning`, `resolving`, `notFound`, `permissionDenied`, `unavailable` | `start()`, `onCode(code)`, `rescan()`, `lookupManually(code)` |

Reglas comunes: cada ViewModel declara sus estados con un `enum` propio; las Views solo escuchan; ningún ViewModel conoce widgets ni dio.

## Interceptor con renovación de sesión

```dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Future<String?> Function() readToken,
    required Future<String?> Function() refreshSession, // devuelve el token nuevo o null
    required SessionEvents events,
  });
}
```

Reglas:
- Ante `401` de una petición con token que no se haya reintentado, llama a `refreshSession`. Varias llamadas simultáneas comparten el mismo `Future`.
- Si devuelve un token, repite la petición una vez con el encabezado nuevo.
- Si devuelve `null`, notifica `onUnauthorized` y deja pasar el error.
- `403` se notifica con `onForbidden` sin cerrar la sesión (sin cambio).
- No intercepta las peticiones al endpoint de token de Keycloak, para evitar bucles.

`refreshSession` la implementa `AuthRepository.refresh()`, que guarda la sesión nueva en `TokenStorage`.
