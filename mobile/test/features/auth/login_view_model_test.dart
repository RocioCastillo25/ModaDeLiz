import 'dart:async';

import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/models/session.dart';
import 'package:checklizz/data/repositories/auth_failure.dart';
import 'package:checklizz/data/repositories/auth_repository.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/services/connectivity_service.dart';
import 'package:checklizz/features/auth/login_view_model.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivity implements ConnectivityService {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;
}

/// Repositorio que cuenta las llamadas y falla o espera según se pida.
class _CountingRepository implements AuthRepository {
  _CountingRepository(this._inner, {this.failure, this.gate});

  final AuthRepository _inner;
  final AuthFailureType? failure;
  final Completer<void>? gate;
  int loginCalls = 0;

  @override
  Future<Session> login(String username, String password) async {
    loginCalls++;
    if (gate != null) await gate!.future;
    if (failure != null) throw AuthFailure(failure!);
    return _inner.login(username, password);
  }

  @override
  Future<Session?> restoreSession() => _inner.restoreSession();

  @override
  Future<void> logout() => _inner.logout();
}

void main() {
  late MockAuthRepository mock;
  late _FakeConnectivity connectivity;

  setUp(() {
    mock = MockAuthRepository(InMemoryTokenStorage(), delay: Duration.zero);
    connectivity = _FakeConnectivity();
  });

  ({LoginViewModel login, SessionViewModel session, _CountingRepository repo}) build({
    AuthFailureType? failure,
    Completer<void>? gate,
  }) {
    final repo = _CountingRepository(mock, failure: failure, gate: gate);
    final session = SessionViewModel(repo);
    final login = LoginViewModel(repo, connectivity, session);
    return (login: login, session: session, repo: repo);
  }

  group('LoginViewModel', () {
    test('inicia sesión con credenciales válidas y pasa a autenticado', () async {
      final vm = build();
      await vm.login.submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );
      expect(vm.login.status, LoginStatus.success);
      expect(vm.session.status, SessionStatus.authenticated);
      expect(vm.session.session?.user.branch?.name, 'Zacatlán');
    });

    test('con credenciales incorrectas muestra el error genérico y no entra', () async {
      final vm = build();
      await vm.login.submit(MockAuthRepository.sellerUsername, 'incorrecta');
      expect(vm.login.status, LoginStatus.error);
      expect(vm.login.error, LoginError.invalidCredentials);
      expect(vm.session.session, isNull);
    });

    test('con usuario inexistente muestra el mismo error que con contraseña incorrecta', () async {
      final vm = build();
      await vm.login.submit('nadie', 'incorrecta');
      expect(vm.login.error, LoginError.invalidCredentials,
          reason: 'no debe revelar si el usuario existe');
    });

    test('con una cuenta desactivada muestra un mensaje propio y no entra', () async {
      final vm = build();
      await vm.login.submit(
        MockAuthRepository.disabledUsername,
        MockAuthRepository.demoPassword,
      );
      expect(vm.login.error, LoginError.accountDisabled);
      expect(vm.session.session, isNull);
    });

    test('con campos vacíos no llama al repositorio', () async {
      final vm = build();
      await vm.login.submit('', '');
      expect(vm.repo.loginCalls, 0, reason: 'no debe enviar la petición');
      expect(vm.login.error, LoginError.emptyFields);
      expect(vm.login.usernameMissing, isTrue);
      expect(vm.login.passwordMissing, isTrue);
    });

    test('indica solo el campo que falta', () async {
      final vm = build();
      await vm.login.submit('demo.vendedor', '');
      expect(vm.login.usernameMissing, isFalse);
      expect(vm.login.passwordMissing, isTrue);
    });

    test('trata solo espacios como campo vacío', () async {
      final vm = build();
      await vm.login.submit('   ', '   ');
      expect(vm.repo.loginCalls, 0);
      expect(vm.login.error, LoginError.emptyFields);
    });

    test('ignora un segundo envío mientras el primero está en curso', () async {
      final gate = Completer<void>();
      final vm = build(gate: gate);
      final first = vm.login.submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );
      await Future<void>.delayed(Duration.zero);
      expect(vm.login.status, LoginStatus.loading);
      expect(vm.login.canSubmit, isFalse, reason: 'el botón debe deshabilitarse');
      await vm.login.submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );
      gate.complete();
      await first;
      expect(vm.repo.loginCalls, 1, reason: 'solo una petición');
    });

    test('sin conexión avisa y no intenta el acceso', () async {
      connectivity.online = false;
      final vm = build();
      await vm.login.submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );
      expect(vm.repo.loginCalls, 0);
      expect(vm.login.error, LoginError.noConnection);
    });

    test('un fallo de red durante el acceso muestra el aviso de conexión', () async {
      final vm = build(failure: AuthFailureType.network);
      await vm.login.submit('a', 'b');
      expect(vm.login.error, LoginError.noConnection);
      expect(vm.login.canSubmit, isTrue, reason: 'debe poder reintentar');
    });

    test('un servicio caído muestra un mensaje claro y permite reintentar', () async {
      final vm = build(failure: AuthFailureType.server);
      await vm.login.submit('a', 'b');
      expect(vm.login.error, LoginError.serviceUnavailable);
      expect(vm.login.canSubmit, isTrue);
    });

    test('una respuesta sin rol o sucursal no permite entrar', () async {
      final vm = build(failure: AuthFailureType.incompleteData);
      await vm.login.submit('a', 'b');
      expect(vm.login.error, LoginError.incompleteData);
      expect(vm.session.session, isNull);
    });

    test('limpia el error al volver a intentar con datos válidos', () async {
      final vm = build();
      await vm.login.submit(MockAuthRepository.sellerUsername, 'mal');
      expect(vm.login.error, isNotNull);
      await vm.login.submit(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      );
      expect(vm.login.error, isNull);
    });
  });
}
