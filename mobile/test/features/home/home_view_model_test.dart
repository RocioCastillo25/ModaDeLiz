import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:checklizz/features/home/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAuthRepository repository;
  late SessionViewModel session;
  late HomeViewModel home;

  setUp(() {
    repository = MockAuthRepository(InMemoryTokenStorage(), delay: Duration.zero);
    session = SessionViewModel(repository);
    home = HomeViewModel(session);
  });

  tearDown(() => home.dispose());

  test('muestra nombre, rol y sucursal de un empleado', () async {
    session.onLoggedIn(
      await repository.login(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      ),
    );
    expect(home.userName, contains('Ana'));
    expect(home.roleLabel, 'Empleado');
    expect(home.branchName, 'Zacatlán');
  });

  test('muestra el rol y la sucursal de un gerente', () async {
    session.onLoggedIn(
      await repository.login(
        MockAuthRepository.managerUsername,
        MockAuthRepository.demoPassword,
      ),
    );
    expect(home.roleLabel, 'Gerente de tienda');
    expect(home.branchName, 'Huauchinango');
  });

  test('ofrece buscar, escanear y traspasos deshabilitados como "próximamente"', () {
    expect(home.sections.map((s) => s.id), [
      HomeSectionId.search,
      HomeSectionId.scanner,
      HomeSectionId.transfers,
    ]);
    for (final section in home.sections) {
      expect(section.enabled, isFalse, reason: '${section.title} aún no está disponible');
      expect(section.hint, 'Próximamente');
    }
  });

  test('avisa a la vista cuando cambia la sesión', () async {
    var notifications = 0;
    home.addListener(() => notifications++);
    session.onLoggedIn(
      await repository.login(
        MockAuthRepository.sellerUsername,
        MockAuthRepository.demoPassword,
      ),
    );
    expect(notifications, greaterThan(0));
  });
}
