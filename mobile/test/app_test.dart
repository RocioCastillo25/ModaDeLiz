import 'package:checklizz/app.dart';
import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/repositories/mock_catalog_repositories.dart';
import 'package:checklizz/data/services/connectivity_service.dart';
import 'package:checklizz/features/auth/login_view_model.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:checklizz/features/busqueda/busqueda_view_model.dart';
import 'package:checklizz/features/ficha_prenda/ficha_view_model.dart';
import 'package:checklizz/features/home/home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  return CheckLizzApp(
    session: session,
    login: login,
    home: HomeViewModel(session),
    features: FeatureFactory(
      createSearch: () => BusquedaViewModel(prendas, branches),
      createFicha: () => FichaViewModel(prendas, session),
    ),
    showDemoHint: true,
  );
}

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
    expect(find.text('Próximamente'), findsNWidgets(2),
        reason: 'el escáner y los traspasos aún no están disponibles');
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
