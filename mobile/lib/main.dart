import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'features/auth/login_view_model.dart';
import 'features/auth/session_view_model.dart';
import 'features/busqueda/busqueda_view_model.dart';
import 'features/ficha_prenda/ficha_view_model.dart';
import 'features/home/home_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final getIt = GetIt.instance;
  registerDependencies(getIt);

  runApp(
    CheckLizzApp(
      session: getIt<SessionViewModel>(),
      login: getIt<LoginViewModel>(),
      home: getIt<HomeViewModel>(),
      features: FeatureFactory(
        createSearch: () => getIt<BusquedaViewModel>(),
        createFicha: () => getIt<FichaViewModel>(),
      ),
      showDemoHint: AppConfig.useMock,
    ),
  );
}
