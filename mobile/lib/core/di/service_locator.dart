import 'package:get_it/get_it.dart';

import '../../data/repositories/api_auth_repository.dart';
import '../../data/repositories/api_catalog_repositories.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/branch_repository.dart';
import '../../data/repositories/inventario_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/mock_catalog_repositories.dart';
import '../../data/repositories/prenda_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/catalog_service.dart';
import '../../data/services/connectivity_plus_service.dart';
import '../../data/services/connectivity_service.dart';
import '../../features/auth/login_view_model.dart';
import '../../features/auth/session_view_model.dart';
import '../../features/busqueda/busqueda_view_model.dart';
import '../../features/ficha_prenda/ficha_view_model.dart';
import '../../features/home/home_view_model.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../security/secure_token_storage.dart';
import '../security/token_storage.dart';

/// Registra las dependencias de la app. Es el único lugar que las ensambla.
///
/// Con [useMock] en `true` se usan los datos de ejemplo; con `false`, la API
/// real. Cambiar entre ambos no exige tocar pantallas ni ViewModels.
void registerDependencies(
  GetIt getIt, {
  bool useMock = AppConfig.useMock,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  String keycloakBaseUrl = AppConfig.keycloakBaseUrl,
}) {
  getIt
    // Seguridad y red.
    ..registerLazySingleton<SessionEvents>(SessionEvents.new)
    ..registerLazySingleton<TokenStorage>(SecureTokenStorage.new)
    ..registerLazySingleton<ConnectivityService>(ConnectivityPlusService.new)
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        baseUrl: apiBaseUrl,
        interceptor: AuthInterceptor(
          readToken: () async =>
              (await getIt<TokenStorage>().read())?.accessToken,
          events: getIt<SessionEvents>(),
          // Se resuelve al usarse, para no crear una dependencia circular.
          refreshSession: () => getIt<AuthRepository>().refresh(),
        ),
      ),
    )
    // Servicios y repositorios: real o simulado según la configuración.
    ..registerLazySingleton<AuthService>(
      () => AuthService(
        getIt<ApiClient>(),
        tokenUrl: AppConfig.keycloakTokenUrl(keycloakBaseUrl),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => useMock
          ? MockAuthRepository(getIt<TokenStorage>())
          : ApiAuthRepository(getIt<AuthService>(), getIt<TokenStorage>()),
    )
    // Catálogo, inventario y ventas: real o simulado según la configuración.
    ..registerLazySingleton<CatalogService>(
      () => CatalogService(getIt<ApiClient>()),
    )
    ..registerLazySingleton<MockCatalogStore>(MockCatalogStore.new)
    ..registerLazySingleton<PrendaRepository>(
      () => useMock
          ? MockPrendaRepository(getIt<MockCatalogStore>())
          : ApiPrendaRepository(getIt<CatalogService>()),
    )
    ..registerLazySingleton<InventarioRepository>(
      () => useMock
          ? MockInventarioRepository(getIt<MockCatalogStore>())
          : ApiInventarioRepository(getIt<CatalogService>()),
    )
    ..registerLazySingleton<BranchRepository>(
      () => useMock
          ? MockBranchRepository(getIt<MockCatalogStore>())
          : ApiBranchRepository(getIt<CatalogService>()),
    )
    // ViewModels.
    ..registerLazySingleton<SessionViewModel>(() {
      final viewModel = SessionViewModel(getIt<AuthRepository>());
      final events = getIt<SessionEvents>();
      events.onUnauthorized = viewModel.onSessionRejected;
      events.onForbidden = viewModel.onForbidden;
      return viewModel;
    })
    ..registerLazySingleton<LoginViewModel>(() {
      final viewModel = LoginViewModel(
        getIt<AuthRepository>(),
        getIt<ConnectivityService>(),
        getIt<SessionViewModel>(),
      );
      // Al cerrar sesión se limpia el estado de este ViewModel.
      getIt<SessionViewModel>().addCleanup(viewModel.reset);
      return viewModel;
    })
    ..registerLazySingleton<HomeViewModel>(
      () => HomeViewModel(getIt<SessionViewModel>()),
    )
    // Uno por pantalla abierta: la pantalla lo descarta al cerrarse.
    ..registerFactory<BusquedaViewModel>(
      () => BusquedaViewModel(
        getIt<PrendaRepository>(),
        getIt<BranchRepository>(),
      ),
    )
    ..registerFactory<FichaViewModel>(
      () => FichaViewModel(getIt<PrendaRepository>(), getIt<SessionViewModel>()),
    );
}
