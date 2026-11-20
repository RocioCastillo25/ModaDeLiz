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
  late MockAuthRepository repository;
  late SessionViewModel session;
  late LoginViewModel login;

  setUp(() {
    storage = InMemoryTokenStorage();
    repository = MockAuthRepository(storage, delay: Duration.zero);
    session = SessionViewModel(repository);
    login = LoginViewModel(repository, _Online(), session);
  });

  group('Administrador', () {
    test('ve el aviso hacia la web y no entra a la pantalla principal', () async {
      await login.submit(
        MockAuthRepository.adminUsername,
        MockAuthRepository.demoPassword,
      );
      expect(login.showAdminNotice, isTrue);
      expect(session.status, isNot(SessionStatus.authenticated));
      expect(session.session, isNull);
    });

    test('no conserva sesión en el dispositivo', () async {
      await login.submit(
        MockAuthRepository.adminUsername,
        MockAuthRepository.demoPassword,
      );
      expect(await storage.read(), isNull);

      final reopened = SessionViewModel(repository);
      await reopened.restore();
      expect(reopened.status, SessionStatus.unauthenticated,
          reason: 'al reabrir la app se pide iniciar sesión');
    });

    test('puede cerrar el aviso y volver al formulario', () async {
      await login.submit(
        MockAuthRepository.adminUsername,
        MockAuthRepository.demoPassword,
      );
      login.dismissAdminNotice();
      expect(login.showAdminNotice, isFalse);
    });

    test('el botón vuelve a quedar habilitado tras el aviso', () async {
      await login.submit(
        MockAuthRepository.adminUsername,
        MockAuthRepository.demoPassword,
      );
      expect(login.canSubmit, isTrue);
    });
  });

  group('Empleado y gerente', () {
    for (final username in [
      MockAuthRepository.sellerUsername,
      MockAuthRepository.managerUsername,
    ]) {
      test('$username no ve el aviso del administrador', () async {
        await login.submit(username, MockAuthRepository.demoPassword);
        expect(login.showAdminNotice, isFalse);
        expect(session.status, SessionStatus.authenticated);
      });
    }
  });
}
