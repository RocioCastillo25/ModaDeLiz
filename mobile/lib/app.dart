import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/motion.dart';
import 'features/auth/admin_notice_view.dart';
import 'features/auth/login_view.dart';
import 'features/auth/login_view_model.dart';
import 'features/auth/session_view_model.dart';
import 'features/busqueda/busqueda_view.dart';
import 'features/busqueda/busqueda_view_model.dart';
import 'features/ficha_prenda/ficha_view.dart';
import 'features/ficha_prenda/ficha_view_model.dart';
import 'features/home/home_view.dart';
import 'features/home/home_view_model.dart';
import 'shared/brand_logo.dart';
import 'shared/gradient_background.dart';

/// Fábricas de los ViewModels de las pantallas del catálogo. Cada pantalla
/// abierta recibe el suyo y lo descarta al salir.
class FeatureFactory {
  const FeatureFactory({required this.createSearch, required this.createFicha});

  final BusquedaViewModel Function() createSearch;
  final FichaViewModel Function() createFicha;
}

/// Aplicación CheckLizz. Recibe sus ViewModels ya construidos (inyección por
/// constructor); no crea ni busca dependencias por sí misma.
class CheckLizzApp extends StatelessWidget {
  const CheckLizzApp({
    super.key,
    required this.session,
    required this.login,
    required this.home,
    this.features,
    this.showDemoHint = false,
  });

  final SessionViewModel session;
  final LoginViewModel login;
  final HomeViewModel home;
  final FeatureFactory? features;
  final bool showDemoHint;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckLizz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SessionGate(
        session: session,
        login: login,
        home: home,
        features: features,
        showDemoHint: showDemoHint,
      ),
    );
  }
}

/// Compuerta de sesión: decide qué pantalla se muestra según el estado.
class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.session,
    required this.login,
    required this.home,
    this.features,
    this.showDemoHint = false,
  });

  final SessionViewModel session;
  final LoginViewModel login;
  final HomeViewModel home;
  final FeatureFactory? features;
  final bool showDemoHint;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_closeScreensWhenSignedOut);
    widget.session.restore();
  }

  @override
  void dispose() {
    widget.session.removeListener(_closeScreensWhenSignedOut);
    super.dispose();
  }

  /// Si la sesión termina (cierre o vencimiento), se cierran las pantallas
  /// abiertas encima de la principal para volver al inicio de sesión.
  void _closeScreensWhenSignedOut() {
    if (widget.session.status == SessionStatus.unauthenticated && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _openSection(HomeSectionId id) {
    final features = widget.features;
    if (features == null) return;
    switch (id) {
      case HomeSectionId.search:
        _openSearch(features);
      case HomeSectionId.scanner:
      case HomeSectionId.transfers:
        break;
    }
  }

  Future<void> _openSearch(FeatureFactory features) async {
    final search = features.createSearch();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => BusquedaView(
          viewModel: search,
          onOpenFicha: (prenda) => _openFicha(features, id: prenda.id),
        ),
      ),
    );
    search.dispose();
  }

  Future<void> _openFicha(FeatureFactory features, {int? id, String? barcode}) async {
    final ficha = features.createFicha();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            FichaView(viewModel: ficha, prendaId: id, barcode: barcode),
      ),
    );
    ficha.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.session, widget.login]),
      builder: (context, _) {
        final Widget screen;
        switch (widget.session.status) {
          case SessionStatus.restoring:
            screen = const _SplashView(key: ValueKey('splash'));
          case SessionStatus.authenticated:
            screen = HomeView(
              key: const ValueKey('home'),
              viewModel: widget.home,
              onOpenSection: _openSection,
            );
          case SessionStatus.unauthenticated:
            screen = widget.login.showAdminNotice
                ? AdminNoticeView(
                    key: const ValueKey('admin-notice'),
                    onBack: widget.login.dismissAdminNotice,
                  )
                : LoginView(
                    key: const ValueKey('login'),
                    viewModel: widget.login,
                    notice: widget.session.notice,
                    showDemoHint: widget.showDemoHint,
                  );
        }
        return AnimatedSwitcher(
          duration: Motion.of(context),
          child: screen,
        );
      },
    );
  }
}

/// Pantalla de espera mientras se restaura la sesión guardada.
class _SplashView extends StatelessWidget {
  const _SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(height: 130),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.pink),
            ],
          ),
        ),
      ),
    );
  }
}
