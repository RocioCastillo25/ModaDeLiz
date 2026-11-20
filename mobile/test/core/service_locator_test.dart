import 'package:checklizz/core/di/service_locator.dart';
import 'package:checklizz/data/repositories/api_auth_repository.dart';
import 'package:checklizz/data/repositories/auth_repository.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
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

  test('el ViewModel de sesión es único: siempre la misma instancia', () {
    final getIt = GetIt.asNewInstance();
    registerDependencies(getIt, useMock: true, apiBaseUrl: 'https://api.prueba');
    expect(identical(getIt<SessionViewModel>(), getIt<SessionViewModel>()), isTrue);
  });
}
