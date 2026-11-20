import 'package:checklizz/data/models/app_role.dart';
import 'package:checklizz/data/models/branch.dart';
import 'package:checklizz/data/models/session.dart';
import 'package:checklizz/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const branch = Branch(id: 'b1', name: 'Zacatlán');
  const seller = User(
    id: 'u1',
    name: 'Ana',
    role: AppRole.seller,
    branch: branch,
  );

  group('AppRole', () {
    test('reconoce los tres códigos de rol de la API', () {
      expect(AppRole.tryParse('ROLE_ADMIN'), AppRole.admin);
      expect(AppRole.tryParse('ROLE_ENCARGADO'), AppRole.manager);
      expect(AppRole.tryParse('ROLE_VENDEDOR'), AppRole.seller);
    });

    test('rechaza un rol desconocido', () {
      expect(AppRole.tryParse('ROLE_OTRO'), isNull,
          reason: 'un rol desconocido no debe aceptarse');
      expect(AppRole.tryParse(null), isNull);
    });

    test('solo el administrador no requiere sucursal', () {
      expect(AppRole.admin.requiresBranch, isFalse);
      expect(AppRole.manager.requiresBranch, isTrue);
      expect(AppRole.seller.requiresBranch, isTrue);
    });

    test('muestra las etiquetas en español', () {
      expect(AppRole.admin.label, 'Administrador');
      expect(AppRole.manager.label, 'Gerente de tienda');
      expect(AppRole.seller.label, 'Empleado');
    });
  });

  group('User', () {
    test('crea un usuario válido desde JSON', () {
      final user = User.fromJson({
        'id': 'u1',
        'name': 'Ana',
        'role': 'ROLE_VENDEDOR',
        'branch': {'id': 'b1', 'name': 'Zacatlán'},
      });
      expect(user.role, AppRole.seller);
      expect(user.branch, branch);
    });

    test('exige sucursal para empleados y gerentes', () {
      expect(
        () => User.fromJson({'id': 'u1', 'name': 'Ana', 'role': 'ROLE_VENDEDOR'}),
        throwsFormatException,
      );
      expect(
        () => User.fromJson({'id': 'u2', 'name': 'Luis', 'role': 'ROLE_ENCARGADO'}),
        throwsFormatException,
      );
    });

    test('permite al administrador no tener sucursal', () {
      final admin = User.fromJson({
        'id': 'u3',
        'name': 'Dueña',
        'role': 'ROLE_ADMIN',
      });
      expect(admin.branch, isNull);
    });

    test('rechaza un rol desconocido', () {
      expect(
        () => User.fromJson({'id': 'u1', 'name': 'Ana', 'role': 'ROLE_X'}),
        throwsFormatException,
      );
    });
  });

  group('Session', () {
    final now = DateTime(2026, 11, 20, 10);

    test('es válida mientras no llegue la expiración', () {
      final session = Session(
        accessToken: 't',
        expiresAt: now.add(const Duration(hours: 1)),
        user: seller,
      );
      expect(session.isValid(now: now), isTrue);
    });

    test('deja de ser válida al llegar la expiración', () {
      final session = Session(accessToken: 't', expiresAt: now, user: seller);
      expect(session.isValid(now: now), isFalse);
      expect(session.isValid(now: now.add(const Duration(minutes: 1))), isFalse);
    });

    test('se guarda y se recupera sin perder datos', () {
      final original = Session(
        accessToken: 'token',
        expiresAt: DateTime.utc(2026, 11, 20, 18),
        user: seller,
      );
      final restored = Session.fromJson(original.toJson());
      expect(restored.accessToken, 'token');
      expect(restored.expiresAt.isAtSameMomentAs(original.expiresAt), isTrue);
      expect(restored.user.branch, branch);
    });

    test('rechaza datos guardados dañados', () {
      expect(() => Session.fromJson({'accessToken': ''}), throwsFormatException);
    });
  });
}
