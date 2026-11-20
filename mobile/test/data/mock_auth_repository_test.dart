import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/models/app_role.dart';
import 'package:checklizz/data/repositories/auth_failure.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryTokenStorage storage;
  late DateTime now;
  late MockAuthRepository repository;

  setUp(() {
    storage = InMemoryTokenStorage();
    now = DateTime(2026, 11, 20, 10);
    repository = MockAuthRepository(
      storage,
      clock: () => now,
      delay: Duration.zero,
    );
  });

  Future<AuthFailureType> failureOf(Future<Object?> Function() action) async {
    try {
      await action();
    } on AuthFailure catch (failure) {
      return failure.type;
    }
    fail('Se esperaba un AuthFailure');
  }

  test('inicia sesión como empleado con su sucursal', () async {
    final session = await repository.login(
      MockAuthRepository.sellerUsername,
      MockAuthRepository.demoPassword,
    );
    expect(session.user.role, AppRole.seller);
    expect(session.user.branch?.name, 'Zacatlán');
    expect(await storage.read(), isNotNull, reason: 'debe guardar la sesión');
  });

  test('inicia sesión como gerente con su sucursal', () async {
    final session = await repository.login(
      MockAuthRepository.managerUsername,
      MockAuthRepository.demoPassword,
    );
    expect(session.user.role, AppRole.manager);
    expect(session.user.branch?.name, 'Huauchinango');
  });

  test('no guarda la sesión de un administrador', () async {
    final session = await repository.login(
      MockAuthRepository.adminUsername,
      MockAuthRepository.demoPassword,
    );
    expect(session.user.role, AppRole.admin);
    expect(await storage.read(), isNull,
        reason: 'el administrador no conserva sesión en el teléfono');
  });

  test('rechaza una contraseña incorrecta con error genérico', () async {
    final type = await failureOf(
      () => repository.login(MockAuthRepository.sellerUsername, 'otra'),
    );
    expect(type, AuthFailureType.invalidCredentials);
  });

  test('rechaza un usuario inexistente igual que una contraseña incorrecta', () async {
    final type = await failureOf(
      () => repository.login('nadie', MockAuthRepository.demoPassword),
    );
    expect(type, AuthFailureType.invalidCredentials,
        reason: 'no debe revelar si el usuario existe');
  });

  test('rechaza una cuenta desactivada', () async {
    final type = await failureOf(
      () => repository.login(
        MockAuthRepository.disabledUsername,
        MockAuthRepository.demoPassword,
      ),
    );
    expect(type, AuthFailureType.accountDisabled);
    expect(await storage.read(), isNull);
  });

  test('restaura la sesión guardada mientras siga vigente', () async {
    await repository.login(
      MockAuthRepository.sellerUsername,
      MockAuthRepository.demoPassword,
    );
    expect(await repository.restoreSession(), isNotNull);
  });

  test('descarta la sesión guardada cuando venció', () async {
    await repository.login(
      MockAuthRepository.sellerUsername,
      MockAuthRepository.demoPassword,
    );
    now = now.add(const Duration(hours: 9));
    expect(await repository.restoreSession(), isNull);
    expect(await storage.read(), isNull, reason: 'debe borrar la sesión vencida');
  });

  test('cerrar sesión borra el token guardado', () async {
    await repository.login(
      MockAuthRepository.sellerUsername,
      MockAuthRepository.demoPassword,
    );
    await repository.logout();
    expect(await storage.read(), isNull);
  });
}
