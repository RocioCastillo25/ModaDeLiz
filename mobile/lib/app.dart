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
import 'data/models/prenda_ficha.dart';
import 'data/models/stock_item.dart';
import 'data/services/barcode_scanner_service.dart';
import 'features/escaner/escaner_view.dart';
import 'features/escaner/escaner_view_model.dart';
import 'features/venta/venta_sheet.dart';
import 'features/venta/venta_view_model.dart';
import 'features/home/home_view.dart';
import 'features/home/home_view_model.dart';
import 'shared/brand_logo.dart';
import 'shared/gradient_background.dart';

/// Fábricas de los ViewModels de las pantallas del catálogo. Cada pantalla
/// abierta recibe el suyo y lo descarta al salir.
class FeatureFactory {
  const FeatureFactory({
    required this.createSearch,
    required this.createFicha,
    required this.createSale,
    required this.createScannerService,
    required this.createScanner,
  });

  final BusquedaViewModel Function() createSearch;
  final FichaViewModel Function() createFicha;

  /// Crea el escáner (adaptador de la cámara) y su ViewModel.
  final BarcodeScannerService Function() createScannerService;
  final EscanerViewModel Function(BarcodeScannerService scanner) createScanner;

  /// Crea el ViewModel de la venta con las existencias que se pueden vender.
  final VentaViewModel Function(int prendaId, List<StockItem> options)
  createSale;
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
        _openScanner(features);
      case HomeSectionId.transfers:
        break;
    }
  }

  Future<void> _openScanner(FeatureFactory features) async {
    final scanner = features.createScannerService();
    final viewModel = features.createScanner(scanner);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => EscanerView(
          viewModel: viewModel,
          scanner: scanner,
          onOpenFicha: (ficha) => _openFicha(features, initial: ficha),
        ),
      ),
    );
    // Libera la cámara al salir del escáner.
    viewModel.dispose();
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

  Future<void> _openFicha(
    FeatureFactory features, {
    int? id,
    String? barcode,
    PrendaFicha? initial,
  }) async {
    final ficha = features.createFicha();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => FichaView(
          viewModel: ficha,
          prendaId: id,
          barcode: barcode,
          initial: initial,
          onSell: (sheetContext, viewModel) =>
              _openSale(features, sheetContext, viewModel),
        ),
      ),
    );
    ficha.dispose();
  }

  /// Abre la hoja de venta y, al cerrarla, actualiza la ficha con la
  /// existencia que devolvió la API (o la recarga si hubo un rechazo).
  Future<void> _openSale(
    FeatureFactory features,
    BuildContext context,
    FichaViewModel ficha,
  ) async {
    final current = ficha.ficha;
    if (current == null) return;
    final sale = features.createSale(current.prenda.id, ficha.ownStock);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundEnd,
      builder: (_) => VentaSheet(
        viewModel: sale,
        prendaName: current.prenda.description,
      ),
    );
    final result = sale.result;
    final latest = sale.latestFicha;
    if (result != null) {
      ficha.applySale(result);
    } else if (latest != null) {
      await ficha.refresh();
    }
    sale.dispose();
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
