import 'package:checklizz/app.dart';
import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/services/connectivity_service.dart';
import 'package:checklizz/features/auth/login_view_model.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
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
  return CheckLizzApp(
    session: session,
    login: login,
    home: HomeViewModel(session),
    showDemoHint: true,
  );
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
    expect(find.text('Próximamente'), findsNWidgets(3));
    expect(find.text('Cerrar sesión'), findsOneWidget);
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
