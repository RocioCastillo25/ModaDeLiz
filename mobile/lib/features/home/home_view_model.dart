import 'package:flutter/foundation.dart';

import '../auth/session_view_model.dart';

/// Secciones que llegarán en los siguientes sprints.
enum HomeSectionId { search, scanner, transfers }

/// Acceso a una sección de la pantalla principal.
class HomeSection {
  const HomeSection({
    required this.id,
    required this.title,
    required this.enabled,
    this.hint,
  });

  final HomeSectionId id;
  final String title;
  final bool enabled;

  /// Leyenda cuando la sección aún no está disponible.
  final String? hint;
}

/// ViewModel de la pantalla principal. No conoce widgets.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._session) {
    _session.addListener(notifyListeners);
  }

  final SessionViewModel _session;

  String get userName => _session.session?.user.name ?? '';
  String get roleLabel => _session.session?.user.role.label ?? '';
  String get branchName => _session.session?.user.branch?.name ?? 'Sin sucursal';

  /// Búsqueda y escáner están disponibles desde el Sprint 2; los traspasos
  /// aparecen como "próximamente" hasta el Sprint 3.
  List<HomeSection> get sections => const [
    HomeSection(
      id: HomeSectionId.search,
      title: 'Buscar prendas',
      enabled: true,
    ),
    HomeSection(
      id: HomeSectionId.scanner,
      title: 'Escanear código',
      enabled: true,
    ),
    HomeSection(
      id: HomeSectionId.transfers,
      title: 'Traspasos',
      enabled: false,
      hint: 'Próximamente',
    ),
  ];

  /// Cierra la sesión del usuario.
  Future<void> logout() => _session.logout();

  /// Devuelve `true` una sola vez si hay un aviso de falta de permisos (403).
  bool takeForbiddenNotice() => _session.takeForbiddenNotice();

  @override
  void dispose() {
    _session.removeListener(notifyListeners);
    super.dispose();
  }
}
