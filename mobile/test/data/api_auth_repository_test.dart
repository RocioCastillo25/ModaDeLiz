import 'package:checklizz/core/network/api_exception.dart';
import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/dto/branch_dto.dart';
import 'package:checklizz/data/dto/profile_dto.dart';
import 'package:checklizz/data/dto/token_response_dto.dart';
import 'package:checklizz/data/models/app_role.dart';
import 'package:checklizz/data/repositories/api_auth_repository.dart';
import 'package:checklizz/data/repositories/auth_failure.dart';
import 'package:checklizz/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servicio falso: devuelve respuestas fijas o lanza el error indicado, y
/// recuerda qué token se usó en cada llamada.
class _FakeAuthService implements AuthService {
  _FakeAuthService({
    this.profile,
    this.branches = const [],
    this.tokenError,
    this.profileError,
    this.branchesError,
  });

  final ProfileDto? profile;
  final List<BranchDto> branches;
  final ApiException? tokenError;
  final ApiException? profileError;
  final ApiException? branchesError;

  int branchCalls = 0;
  String? profileToken;
  String? branchesToken;

  @override
  Future<TokenResponseDto> requestToken(String username, String password) async {
    if (tokenError != null) throw tokenError!;
    return const TokenResponseDto(accessToken: 'token-x', expiresIn: 3600);
  }

  @override
  Future<ProfileDto> fetchProfile(String accessToken) async {
    profileToken = accessToken;
    if (profileError != null) throw profileError!;
    return profile!;
  }

  @override
  Future<List<BranchDto>> fetchBranches(String accessToken) async {
    branchCalls++;
    branchesToken = accessToken;
    if (branchesError != null) throw branchesError!;
    return branches;
  }
}

ProfileDto _perfil({String rol = 'empleado', int? sucursalId = 2}) {
  return ProfileDto.fromJson({
    'id': 7,
    'nombre': 'Ana',
    'rol': rol,
    'sucursalId': sucursalId,
    'keycloakId': '00000000-0000-0000-0000-000000000000',
  });
}

const _sucursales = [
  BranchDto(id: 1, name: 'Huauchinango'),
  BranchDto(id: 2, name: 'Zacatlán'),
];

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

  group('Inicio de sesión con Keycloak y la API', () {
    test('un empleado entra con su nombre, rol y el nombre de su sucursal', () async {
      final service = _FakeAuthService(profile: _perfil(), branches: _sucursales);
      final session = await build(service).login('ana', 'clave');

      expect(session.user.name, 'Ana');
      expect(session.user.role, AppRole.seller);
      expect(session.user.branch?.name, 'Zacatlán');
      expect(session.expiresAt, now.add(const Duration(seconds: 3600)));
    });

    test('guarda la sesión de un empleado', () async {
      final service = _FakeAuthService(profile: _perfil(), branches: _sucursales);
      await build(service).login('ana', 'clave');
      expect((await storage.read())?.accessToken, 'token-x');
    });

    test('usa el token recién emitido para pedir el perfil y las sucursales', () async {
      final service = _FakeAuthService(profile: _perfil(), branches: _sucursales);
      await build(service).login('ana', 'clave');
      expect(service.profileToken, 'token-x');
      expect(service.branchesToken, 'token-x');
    });

    test('un gerente entra con "Gerente de tienda" y su sucursal', () async {
      final service = _FakeAuthService(
        profile: _perfil(rol: 'gerente', sucursalId: 1),
        branches: _sucursales,
      );
      final session = await build(service).login('luis', 'clave');
      expect(session.user.role, AppRole.manager);
      expect(session.user.branch?.name, 'Huauchinango');
    });

    test('un administrador no necesita sucursal ni se guarda su sesión', () async {
      final service = _FakeAuthService(
        profile: _perfil(rol: 'administrador', sucursalId: null),
      );
      final session = await build(service).login('dueña', 'clave');

      expect(session.user.role, AppRole.admin);
      expect(service.branchCalls, 0, reason: 'no hace falta pedir sucursales');
      expect(await storage.read(), isNull,
          reason: 'el administrador no conserva sesión en el teléfono');
    });

    test('rechaza a un empleado cuya sucursal no aparece en la lista', () async {
      final service = _FakeAuthService(
        profile: _perfil(sucursalId: 99),
        branches: _sucursales,
      );
      expect(await failureOf(build(service)), AuthFailureType.incompleteData);
      expect(await storage.read(), isNull);
    });

    test('rechaza a un empleado sin sucursal asignada', () async {
      final service = _FakeAuthService(
        profile: _perfil(sucursalId: null),
        branches: _sucursales,
      );
      expect(await failureOf(build(service)), AuthFailureType.incompleteData);
    });

    test('rechaza un rol desconocido', () async {
      final service = _FakeAuthService(
        profile: _perfil(rol: 'visitante'),
        branches: _sucursales,
      );
      expect(await failureOf(build(service)), AuthFailureType.incompleteData);
    });
  });

  group('Errores al pedir el token', () {
    test('un 401 de Keycloak se muestra como credenciales incorrectas', () async {
      final service = _FakeAuthService(
        tokenError: const ApiException(
          ApiErrorKind.unauthorized,
          statusCode: 401,
          code: 'invalid_grant',
          description: 'Invalid user credentials',
        ),
      );
      expect(await failureOf(build(service)), AuthFailureType.invalidCredentials);
    });

    test('"Account disabled" de Keycloak se muestra como cuenta desactivada', () async {
      final service = _FakeAuthService(
        tokenError: const ApiException(
          ApiErrorKind.badRequest,
          statusCode: 400,
          code: 'invalid_grant',
          description: 'Account disabled',
        ),
      );
      expect(await failureOf(build(service)), AuthFailureType.accountDisabled);
    });

    test('otro rechazo con 400 no revela detalles: credenciales incorrectas', () async {
      final service = _FakeAuthService(
        tokenError: const ApiException(
          ApiErrorKind.badRequest,
          statusCode: 400,
          code: 'invalid_request',
        ),
      );
      expect(await failureOf(build(service)), AuthFailureType.invalidCredentials);
    });

    test('un fallo de conexión se convierte en error de red', () async {
      final service = _FakeAuthService(
        tokenError: const ApiException(ApiErrorKind.network),
      );
      expect(await failureOf(build(service)), AuthFailureType.network);
    });

    test('un error 5xx se convierte en error del servicio', () async {
      final service = _FakeAuthService(
        tokenError: const ApiException(ApiErrorKind.server, statusCode: 503),
      );
      expect(await failureOf(build(service)), AuthFailureType.server);
    });
  });

  group('Errores al pedir el perfil y las sucursales', () {
    test('un 401 de la API con un token recién emitido es un fallo del servicio', () async {
      final service = _FakeAuthService(
        profileError: const ApiException(ApiErrorKind.unauthorized, statusCode: 401),
      );
      expect(await failureOf(build(service)), AuthFailureType.server);
    });

    test('un 403 de la API significa que la cuenta no puede usar la app', () async {
      final service = _FakeAuthService(
        profileError: const ApiException(
          ApiErrorKind.forbidden,
          statusCode: 403,
          code: 'PROHIBIDO',
        ),
      );
      expect(await failureOf(build(service)), AuthFailureType.accountDisabled);
    });

    test('un usuario inactivo en la API se muestra como cuenta desactivada', () async {
      final service = _FakeAuthService(
        profileError: const ApiException(
          ApiErrorKind.badRequest,
          statusCode: 400,
          code: 'USUARIO_INACTIVO',
        ),
      );
      expect(await failureOf(build(service)), AuthFailureType.accountDisabled);
    });

    test('un fallo de conexión al pedir las sucursales es error de red', () async {
      final service = _FakeAuthService(
        profile: _perfil(),
        branchesError: const ApiException(ApiErrorKind.network),
      );
      expect(await failureOf(build(service)), AuthFailureType.network);
      expect(await storage.read(), isNull, reason: 'no guarda una sesión a medias');
    });
  });

  group('DTOs del contrato', () {
    test('el token de Keycloak exige access_token y expires_in', () {
      expect(
        () => TokenResponseDto.fromJson({'expires_in': 300}),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => TokenResponseDto.fromJson({'access_token': 'a', 'expires_in': 0}),
        throwsA(isA<AuthFailure>()),
      );
      final ok = TokenResponseDto.fromJson({'access_token': 'a', 'expires_in': 300});
      expect(ok.expiresIn, 300);
    });

    test('el perfil de /me exige id, nombre y rol', () {
      expect(
        () => ProfileDto.fromJson({'id': 1, 'rol': 'empleado'}),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => ProfileDto.fromJson({'id': 1, 'nombre': 'Ana', 'rol': 'empleado', 'sucursalId': 'x'}),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('la sucursal usa los campos id y nombre', () {
      final b = BranchDto.fromJson({'id': 3, 'nombre': 'Xicotepec', 'ubicacion': 'Centro'});
      expect(b.toBranch().id, '3');
      expect(b.toBranch().name, 'Xicotepec');
      expect(() => BranchDto.fromJson({'id': 3}), throwsA(isA<AuthFailure>()));
    });
  });
}
