import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/services/connectivity_service.dart';
import 'package:checklizz/features/auth/login_view_model.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:checklizz/features/home/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Online implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;
}

void main() {
  late InMemoryTokenStorage storage;
  late MockAuthRepository repository;
  late SessionViewModel session;
  late LoginViewModel login;
  late HomeViewModel home;

  setUp(() {
    storage = InMemoryTokenStorage();
    repository = MockAuthRepository(storage, delay: Duration.zero);
    session = SessionViewModel(repository);
    login = LoginViewModel(repository, _Online(), session);
    home = HomeViewModel(session);
    session.addCleanup(login.reset);
  });

  tearDown(() => home.dispose());

  Future<void> signIn() => login.submit(
    MockAuthRepository.sellerUsername,
    MockAuthRepository.demoPassword,
  );

  group('Cierre de sesión', () {
    test('borra el token guardado y pasa a no autenticado', () async {
      await signIn();
      expect(await storage.read(), isNotNull);

      await home.logout();

      expect(await storage.read(), isNull, reason: 'el token debe borrarse');
      expect(session.status, SessionStatus.unauthenticated);
      expect(session.session, isNull);
    });

    test('limpia el estado del inicio de sesión', () async {
      await login.submit(MockAuthRepository.sellerUsername, 'mal');
      expect(login.error, isNotNull);
      await signIn();

      await home.logout();

      expect(login.status, LoginStatus.idle);
      expect(login.error, isNull);
    });

    test('no deja datos del usuario en la pantalla principal', () async {
      await signIn();
      await home.logout();
      expect(home.userName, isEmpty);
      expect(home.roleLabel, isEmpty);
    });

    test('al reabrir la app tras cerrar sesión se pide iniciar sesión', () async {
      await signIn();
      await home.logout();

      final reopened = SessionViewModel(repository);
      await reopened.restore();

      expect(reopened.status, SessionStatus.unauthenticated);
    });

    test('no muestra aviso de sesión vencida al cerrar sesión por decisión propia', () async {
      await signIn();
      await home.logout();
      expect(session.notice, isNull);
    });
  });
}
