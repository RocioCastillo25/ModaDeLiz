import 'package:checklizz/core/di/service_locator.dart';
import 'package:checklizz/data/repositories/api_auth_repository.dart';
import 'package:checklizz/data/repositories/api_catalog_repositories.dart';
import 'package:checklizz/data/repositories/auth_repository.dart';
import 'package:checklizz/data/repositories/branch_repository.dart';
import 'package:checklizz/data/repositories/inventario_repository.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/repositories/mock_catalog_repositories.dart';
import 'package:checklizz/data/repositories/prenda_repository.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  test('con USE_MOCK activo usa el repositorio simulado', () {
    final getIt = GetIt.asNewInstance();
    registerDependencies(getIt, useMock: true, apiBaseUrl: 'https://api.prueba');
    expect(getIt<AuthRepository>(), isA<MockAuthRepository>());
  });

  test('con USE_MOCK desactivado usa el repositorio real', () {
    final getIt = GetIt.asNewInstance();
    registerDependencies(getIt, useMock: false, apiBaseUrl: 'https://api.prueba');
    expect(getIt<AuthRepository>(), isA<ApiAuthRepository>());
  });

  test('el ViewModel de sesión funciona igual con cualquiera de los dos', () {
    for (final useMock in [true, false]) {
      final getIt = GetIt.asNewInstance();
      registerDependencies(getIt, useMock: useMock, apiBaseUrl: 'https://api.prueba');
      expect(getIt<SessionViewModel>(), isA<SessionViewModel>());
    }
  });

  test('con USE_MOCK activo, el catálogo, las ventas y las sucursales son simulados', () {
    final getIt = GetIt.asNewInstance();
    registerDependencies(getIt, useMock: true, apiBaseUrl: 'https://api.prueba');
    expect(getIt<PrendaRepository>(), isA<MockPrendaRepository>());
    expect(getIt<InventarioRepository>(), isA<MockInventarioRepository>());
    expect(getIt<BranchRepository>(), isA<MockBranchRepository>());
  });

  test('con USE_MOCK desactivado, el catálogo, las ventas y las sucursales son reales', () {
    final getIt = GetIt.asNewInstance();
    registerDependencies(getIt, useMock: false, apiBaseUrl: 'https://api.prueba');
    expect(getIt<PrendaRepository>(), isA<ApiPrendaRepository>());
    expect(getIt<InventarioRepository>(), isA<ApiInventarioRepository>());
    expect(getIt<BranchRepository>(), isA<ApiBranchRepository>());
  });

  test('una venta simulada se ve después en la ficha', () async {
    final getIt = GetIt.asNewInstance();
    registerDependencies(getIt, useMock: true, apiBaseUrl: 'https://api.prueba');
    final ficha = await getIt<PrendaRepository>().getById(1);
    final line = ficha.stock.firstWhere((item) => item.quantity >= 3);
    await getIt<InventarioRepository>().sell(line.id, 2);
    final after = await getIt<PrendaRepository>().getById(1);
    expect(after.stock.firstWhere((item) => item.id == line.id).quantity, line.quantity - 2);
  });

  test('el ViewModel de sesión es único: siempre la misma instancia', () {
    final getIt = GetIt.asNewInstance();
    registerDependencies(getIt, useMock: true, apiBaseUrl: 'https://api.prueba');
    expect(identical(getIt<SessionViewModel>(), getIt<SessionViewModel>()), isTrue);
  });
}
