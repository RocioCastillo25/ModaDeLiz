import 'package:checklizz/app.dart';
import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/repositories/mock_catalog_repositories.dart';
import 'package:checklizz/data/services/connectivity_service.dart';
import 'package:checklizz/features/auth/login_view_model.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:checklizz/features/busqueda/busqueda_view_model.dart';
import 'package:checklizz/features/ficha_prenda/ficha_view_model.dart';
import 'package:checklizz/data/services/barcode_scanner_service.dart';
import 'package:checklizz/features/escaner/escaner_view_model.dart';
import 'package:checklizz/features/venta/venta_sheet.dart';
import 'package:checklizz/features/venta/venta_view_model.dart';
import 'package:checklizz/features/home/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_barcode_scanner_service.dart';

class _Online implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;
}

Widget _buildApp() {
  final storage = InMemoryTokenStorage();
  final repository = MockAuthRepository(storage, delay: Duration.zero);
  final session = SessionViewModel(repository);
  final login = LoginViewModel(repository, _Online(), session);
  session.addCleanup(login.reset);
  final store = MockCatalogStore(delay: Duration.zero);
  final prendas = MockPrendaRepository(store);
  final branches = MockBranchRepository(store);
  final inventario = MockInventarioRepository(store);
  return CheckLizzApp(
    session: session,
    login: login,
    home: HomeViewModel(session),
    features: FeatureFactory(
      createSearch: () => BusquedaViewModel(prendas, branches),
      createFicha: () => FichaViewModel(prendas, session),
      createSale: (prendaId, options) => VentaViewModel(
        inventario,
        prendas,
        _Online(),
        prendaId: prendaId,
        options: options,
      ),
      createScannerService: () => _scanner = FakeBarcodeScannerService(),
      createScanner: (scanner) => EscanerViewModel(scanner, prendas),
    ),
    showDemoHint: true,
  );
}

/// Escáner falso de la prueba en curso, para emitir códigos a mano.
late FakeBarcodeScannerService _scanner;

/// Teléfono real, para ver las secciones sin desplazar.
void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2200);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Future<void> _signIn(WidgetTester tester, {String user = 'demo.vendedor'}) async {
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), user);
  await tester.enterText(find.byType(TextField).at(1), 'demo1234');
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el inicio de sesión con el nombre CheckLizz', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    expect(find.text('CheckLizz'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('MODO DE PRUEBA'), findsOneWidget,
        reason: 'los datos de ejemplo deben estar identificados');
  });

  testWidgets('con campos vacíos indica qué falta y no entra', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu usuario'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('con credenciales válidas llega a la pantalla principal', (tester) async {
    // Tamaño de un teléfono real, para ver las tres secciones sin desplazar.
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'demo.vendedor');
    await tester.enterText(find.byType(TextField).at(1), 'demo1234');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Empleado'), findsOneWidget);
    expect(find.text('Zacatlán'), findsOneWidget);
    expect(find.text('Buscar prendas'), findsOneWidget);
    expect(find.text('Escanear código'), findsOneWidget);
    expect(find.text('Próximamente'), findsOneWidget,
        reason: 'solo los traspasos aún no están disponibles');
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('desde la pantalla principal se busca y se abre la ficha', (tester) async {
    _phoneSize(tester);
    await _signIn(tester);

    await tester.tap(find.text('Buscar prendas'));
    await tester.pumpAndSettle();
    expect(find.text('Blusa floral manga corta'), findsOneWidget);
    expect(find.text('Jeans skinny azul'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'jeans');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Blusa floral manga corta'), findsNothing);

    await tester.tap(find.text('Jeans skinny azul'));
    await tester.pumpAndSettle();
    expect(find.text('Ficha de prenda'), findsOneWidget);
    expect(find.text('Tu sucursal'), findsOneWidget,
        reason: 'la sucursal del usuario aparece destacada');
    expect(find.text('Zacatlán'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Solicitar traspaso'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Solicitar traspaso'), findsOneWidget);
    expect(find.text('Próximamente'), findsOneWidget,
        reason: 'el traspaso aparece deshabilitado, con su leyenda');
    await tester.scrollUntilVisible(
      find.text('Tu sucursal'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar prendas'), findsOneWidget);
  });

  /// Abre la ficha de la blusa y la hoja de venta.
  Future<void> openSaleSheet(WidgetTester tester) async {
    _phoneSize(tester);
    await _signIn(tester);
    await tester.tap(find.text('Buscar prendas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blusa floral manga corta'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Descontar piezas'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Descontar piezas'));
    await tester.pumpAndSettle();
  }

  testWidgets('vende piezas de la sucursal propia y la ficha muestra la existencia nueva', (tester) async {
    await openSaleSheet(tester);
    Finder inSheet(String text) =>
        find.descendant(of: find.byType(VentaSheet), matching: find.text(text));
    expect(inSheet('Talla M · Rosa'), findsOneWidget);
    expect(inSheet('Talla CH · Blanco'), findsOneWidget);
    expect(inSheet('Talla G · Rosa'), findsNothing,
        reason: 'solo se ofrecen las existencias de la sucursal del usuario');

    await tester.enterText(find.byType(TextField).last, '2');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Confirmas la venta?'), findsOneWidget);
    expect(find.text('Talla M · Rosa · 2 piezas'), findsOneWidget);

    await tester.tap(find.text('Confirmar venta'));
    await tester.pumpAndSettle();
    expect(find.text('Venta registrada'), findsOneWidget);
    expect(find.textContaining('ahora hay 3 piezas en Zacatlán'), findsOneWidget);

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(find.text('3 · Disponible'), findsWidgets,
        reason: 'la ficha se actualiza con la existencia que devolvió la API');
  });

  testWidgets('pedir más piezas de las que hay muestra la existencia actual', (tester) async {
    await openSaleSheet(tester);
    await tester.enterText(find.byType(TextField).last, '99');
    await tester.pump();
    expect(find.text('Solo hay 5 piezas.'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar venta'));
    await tester.pumpAndSettle();
    expect(find.text('Solo quedan 5 piezas.'), findsOneWidget);
    expect(find.textContaining('No se descontó nada'), findsOneWidget);

    await tester.tap(find.text('Corregir cantidad'));
    await tester.pumpAndSettle();
    expect(find.text('Cantidad de piezas'), findsOneWidget);
  });

  testWidgets('sin escribir una cantidad no se puede continuar', (tester) async {
    await openSaleSheet(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Confirmas la venta?'), findsNothing);
    expect(find.text('Cantidad de piezas'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '0');
    await tester.pump();
    expect(find.text('La cantidad debe ser mayor que cero.'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Confirmas la venta?'), findsNothing);
  });

  group('Escáner', () {
    Future<void> openScanner(WidgetTester tester) async {
      _phoneSize(tester);
      await _signIn(tester);
      await tester.tap(find.text('Escanear código'));
      await tester.pumpAndSettle();
    }

    testWidgets('antes de pedir la cámara explica para qué se usa', (tester) async {
      await openScanner(tester);
      expect(find.text('Usaremos la cámara'), findsOneWidget);
      expect(find.text('Activar cámara'), findsOneWidget);
      expect(_scanner.startCalls, 0, reason: 'la cámara aún no se activa');
    });

    testWidgets('al leer una etiqueta registrada abre la ficha y al volver sigue escaneando', (tester) async {
      await openScanner(tester);
      await tester.tap(find.text('Activar cámara'));
      await tester.pumpAndSettle();
      expect(_scanner.startCalls, 1);
      expect(find.text('Apunta al código de barras de la etiqueta'), findsOneWidget);

      _scanner.emit('7501000000029');
      await tester.pumpAndSettle();
      expect(find.text('Ficha de prenda'), findsOneWidget);
      expect(find.text('Vestido midi negro'), findsOneWidget);

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Escanear código'), findsWidgets);
      expect(find.text('Apunta al código de barras de la etiqueta'), findsOneWidget);
    });

    testWidgets('un código desconocido avisa y permite escanear otra vez', (tester) async {
      await openScanner(tester);
      await tester.tap(find.text('Activar cámara'));
      await tester.pumpAndSettle();
      _scanner.emit('0000');
      await tester.pumpAndSettle();
      expect(find.textContaining('Prenda no encontrada'), findsOneWidget);

      await tester.tap(find.text('Escanear otra vez'));
      await tester.pumpAndSettle();
      expect(find.text('Apunta al código de barras de la etiqueta'), findsOneWidget);
    });

    testWidgets('con el permiso negado ofrece buscar el código a mano', (tester) async {
      await openScanner(tester);
      await tester.tap(find.text('Activar cámara'));
      await tester.pumpAndSettle();
      _scanner.emitError(ScannerError.permissionDenied);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sin permiso de cámara'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '7501000000036');
      await tester.tap(find.text('Buscar por código'));
      await tester.pumpAndSettle();
      expect(find.text('Jeans skinny azul'), findsOneWidget);
    });

    testWidgets('la búsqueda manual con el código vacío pide escribirlo', (tester) async {
      await openScanner(tester);
      await tester.tap(find.text('Escribir el código a mano'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buscar por código'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe el código de la etiqueta.'), findsOneWidget);
    });
  });

  testWidgets('una búsqueda sin resultados muestra un mensaje claro', (tester) async {
    _phoneSize(tester);
    await _signIn(tester);
    await tester.tap(find.text('Buscar prendas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'abrigo de piel');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('No encontramos prendas con esos datos.'), findsOneWidget);
  });

  testWidgets('un 403 en una pantalla del catálogo avisa sin cerrar la sesión', (tester) async {
    _phoneSize(tester);
    await _signIn(tester);
    await tester.tap(find.text('Buscar prendas'));
    await tester.pumpAndSettle();

    final gate = tester.widget<SessionGate>(
      find.byType(SessionGate, skipOffstage: false),
    );
    gate.session.onForbidden();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No tienes permiso para realizar esta acción.'), findsOneWidget);
    expect(find.text('Blusa floral manga corta'), findsOneWidget,
        reason: 'la sesión y la pantalla siguen abiertas');
  });

  testWidgets('al cerrar sesión se cierran las pantallas abiertas', (tester) async {
    _phoneSize(tester);
    await _signIn(tester);
    await tester.tap(find.text('Buscar prendas'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar prendas'), findsWidgets);
    // Simula que la sesión terminó mientras la búsqueda estaba abierta.
    final gate = tester.widget<SessionGate>(
      find.byType(SessionGate, skipOffstage: false),
    );
    await gate.session.logout();
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Buscar prendas'), findsNothing);
  });

  testWidgets('con contraseña incorrecta muestra el mensaje genérico', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'demo.vendedor');
    await tester.enterText(find.byType(TextField).at(1), 'mal');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.textContaining('incorrectos'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
  });
}
