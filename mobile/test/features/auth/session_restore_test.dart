import 'package:checklizz/core/network/auth_interceptor.dart';
import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/services/connectivity_service.dart';
import 'package:checklizz/features/auth/login_view_model.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Online implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;
}

void main() {
  late InMemoryTokenStorage storage;
  late DateTime now;

  setUp(() {
    storage = InMemoryTokenStorage();
    now = DateTime(2026, 11, 20, 10);
  });

  MockAuthRepository buildRepository() => MockAuthRepository(
    storage,
    clock: () => now,
    delay: Duration.zero,
    tokenLifetime: const Duration(hours: 1),
  );

  Future<void> signIn(MockAuthRepository repository) async {
    final session = SessionViewModel(repository);
    await LoginViewModel(repository, _Online(), session).submit(
      MockAuthRepository.sellerUsername,
      MockAuthRepository.demoPassword,
    );
  }

  group('Sesión persistente', () {
    test('con sesión vigente entra directo sin pedir credenciales', () async {
      final repository = buildRepository();
      await signIn(repository);

      final reopened = SessionViewModel(repository);
      expect(reopened.status, SessionStatus.restoring);
      await reopened.restore();

      expect(reopened.status, SessionStatus.authenticated);
      expect(reopened.session?.user.name, contains('Ana'));
    });

    test('sin sesión guardada pide iniciar sesión', () async {
      final reopened = SessionViewModel(buildRepository());
      await reopened.restore();
      expect(reopened.status, SessionStatus.unauthenticated);
    });

    test('con sesión vencida pide iniciar sesión y borra el token', () async {
      final repository = buildRepository();
      await signIn(repository);
      now = now.add(const Duration(hours: 2));

      final reopened = SessionViewModel(repository);
      await reopened.restore();

      expect(reopened.status, SessionStatus.unauthenticated);
      expect(await storage.read(), isNull);
    });
  });

  group('Respuestas 401 y 403', () {
    test('un 401 vuelve al inicio de sesión con aviso de sesión vencida', () async {
      final repository = buildRepository();
      final session = SessionViewModel(repository);
      await LoginViewModel(repository, _Online(), session).submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );
      expect(session.status, SessionStatus.authenticated);

      await session.onSessionRejected();

      expect(session.status, SessionStatus.unauthenticated);
      expect(session.notice, SessionNotice.expired);
      expect(await storage.read(), isNull, reason: 'debe borrar el token');
    });

    test('el aviso de sesión vencida se quita al iniciar sesión de nuevo', () async {
      final repository = buildRepository();
      final session = SessionViewModel(repository);
      final login = LoginViewModel(repository, _Online(), session);
      await login.submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );
      await session.onSessionRejected();

      await login.submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );

      expect(session.status, SessionStatus.authenticated);
      expect(session.notice, isNull);
    });

    test('un 401 sin sesión abierta no muestra aviso', () async {
      final session = SessionViewModel(buildRepository());
      await session.restore();
      await session.onSessionRejected();
      expect(session.notice, isNull);
    });

    test('un 403 avisa la falta de permisos sin cerrar la sesión', () async {
      final repository = buildRepository();
      final session = SessionViewModel(repository);
      await LoginViewModel(repository, _Online(), session).submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );

      session.onForbidden();

      expect(session.status, SessionStatus.authenticated,
          reason: 'un 403 no debe cerrar la sesión');
      expect(session.takeForbiddenNotice(), isTrue);
      expect(session.takeForbiddenNotice(), isFalse,
          reason: 'el aviso se entrega una sola vez');
    });

    test('los eventos de red se conectan con el estado de sesión', () async {
      final repository = buildRepository();
      final session = SessionViewModel(repository);
      final events = SessionEvents()
        ..onUnauthorized = session.onSessionRejected
        ..onForbidden = session.onForbidden;
      await LoginViewModel(repository, _Online(), session).submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );

      events.onForbidden?.call();
      expect(session.status, SessionStatus.authenticated);

      events.onUnauthorized?.call();
      await Future<void>.delayed(Duration.zero);
      expect(session.status, SessionStatus.unauthenticated);
    });
  });
}
