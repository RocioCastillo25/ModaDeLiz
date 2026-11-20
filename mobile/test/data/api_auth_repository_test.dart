import 'package:checklizz/core/network/api_exception.dart';
import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/dto/login_response_dto.dart';
import 'package:checklizz/data/models/app_role.dart';
import 'package:checklizz/data/repositories/api_auth_repository.dart';
import 'package:checklizz/data/repositories/auth_failure.dart';
import 'package:checklizz/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: devuelve una respuesta fija o lanza un error de red.
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.response, this.error});

  final LoginResponseDto? response;
  final ApiException? error;

  @override
  Future<LoginResponseDto> login(String username, String password) async {
    if (error != null) throw error!;
    return response!;
  }
}

LoginResponseDto _dto({String role = 'ROLE_VENDEDOR', bool withBranch = true}) {
  return LoginResponseDto.fromJson({
    'accessToken': 'token-x',
    'expiresIn': 3600,
    'user': {
      'id': 'u1',
      'name': 'Ana',
      'role': role,
      if (withBranch) 'branch': {'id': 'b1', 'name': 'Zacatlán'},
    },
  });
}

void main() {
  final now = DateTime(2026, 11, 20, 10);
  late InMemoryTokenStorage storage;

  setUp(() => storage = InMemoryTokenStorage());

  ApiAuthRepository build(_FakeAuthService service) =>
      ApiAuthRepository(service, storage, clock: () => now);

  Future<AuthFailureType> failureOf(ApiAuthRepository repo) async {
    try {
      await repo.login('ana', 'clave');
    } on AuthFailure catch (failure) {
      return failure.type;
    }
    fail('Se esperaba un AuthFailure');
  }

  group('ApiAuthRepository', () {
    test('inicia sesión y guarda la sesión de un empleado', () async {
      final session = await build(_FakeAuthService(response: _dto())).login('a', 'b');
      expect(session.user.role, AppRole.seller);
      expect(session.expiresAt, now.add(const Duration(seconds: 3600)));
      expect((await storage.read())?.accessToken, 'token-x');
    });

    test('no guarda la sesión de un administrador', () async {
      final repo = build(
        _FakeAuthService(response: _dto(role: 'ROLE_ADMIN', withBranch: false)),
      );
      final session = await repo.login('a', 'b');
      expect(session.user.role, AppRole.admin);
      expect(await storage.read(), isNull);
    });

    test('un 401 se convierte en credenciales incorrectas', () async {
      final repo = build(
        _FakeAuthService(error: const ApiException(ApiErrorKind.unauthorized)),
      );
      expect(await failureOf(repo), AuthFailureType.invalidCredentials);
    });

    test('un 403 se convierte en cuenta desactivada', () async {
      final repo = build(
        _FakeAuthService(error: const ApiException(ApiErrorKind.forbidden)),
      );
      expect(await failureOf(repo), AuthFailureType.accountDisabled);
    });

    test('un fallo de conexión se convierte en error de red', () async {
      final repo = build(
        _FakeAuthService(error: const ApiException(ApiErrorKind.network)),
      );
      expect(await failureOf(repo), AuthFailureType.network);
    });

    test('un error 5xx se convierte en error del servicio', () async {
      final repo = build(
        _FakeAuthService(error: const ApiException(ApiErrorKind.server, statusCode: 500)),
      );
      expect(await failureOf(repo), AuthFailureType.server);
    });

    test('rechaza una respuesta sin sucursal para un empleado', () async {
      final repo = build(_FakeAuthService(response: _dto(withBranch: false)));
      expect(await failureOf(repo), AuthFailureType.incompleteData);
      expect(await storage.read(), isNull);
    });

    test('rechaza una respuesta con rol desconocido', () async {
      final repo = build(_FakeAuthService(response: _dto(role: 'ROLE_OTRO')));
      expect(await failureOf(repo), AuthFailureType.incompleteData);
    });
  });

  group('LoginResponseDto', () {
    test('rechaza una respuesta sin token', () {
      expect(
        () => LoginResponseDto.fromJson({'expiresIn': 10, 'user': <String, dynamic>{}}),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
