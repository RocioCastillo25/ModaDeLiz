import 'package:flutter/foundation.dart';

import '../../data/models/session.dart';
import '../../data/repositories/auth_repository.dart';

/// Estado global de la sesión.
enum SessionStatus { restoring, authenticated, unauthenticated }

/// Avisos que se muestran al volver al inicio de sesión.
enum SessionNotice { expired }

/// ViewModel de la sesión: decide si se muestra el inicio de sesión o la
/// pantalla principal. No conoce widgets.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._repository);

  final AuthRepository _repository;
  final List<VoidCallback> _cleanups = [];

  SessionStatus _status = SessionStatus.restoring;
  Session? _session;
  SessionNotice? _notice;
  bool _forbiddenNotice = false;

  SessionStatus get status => _status;
  Session? get session => _session;
  SessionNotice? get notice => _notice;

  /// Registra una acción que limpia el estado de otro ViewModel al cerrar sesión.
  void addCleanup(VoidCallback cleanup) => _cleanups.add(cleanup);

  /// Restaura la sesión guardada al abrir la app.
  Future<void> restore() async {
    try {
      final restored = await _repository.restoreSession();
      if (restored == null) {
        _setUnauthenticated();
      } else {
        _session = restored;
        _status = SessionStatus.authenticated;
        notifyListeners();
      }
    } catch (_) {
      _setUnauthenticated();
    }
  }

  /// Se llama cuando el inicio de sesión fue exitoso.
  void onLoggedIn(Session session) {
    _session = session;
    _notice = null;
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  /// Cierra la sesión: borra el token y limpia el estado de los ViewModels.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      _runCleanups();
      _notice = null;
      _setUnauthenticated();
    }
  }

  /// La API rechazó la sesión (401): se vuelve al inicio de sesión con aviso.
  Future<void> onSessionRejected() async {
    if (_status != SessionStatus.authenticated) return;
    try {
      await _repository.logout();
    } finally {
      _runCleanups();
      _notice = SessionNotice.expired;
      _setUnauthenticated();
    }
  }

  /// La API negó un permiso (403): se avisa sin cerrar la sesión.
  void onForbidden() {
    _forbiddenNotice = true;
    notifyListeners();
  }

  /// Devuelve `true` una sola vez si hay un aviso de falta de permisos pendiente.
  bool takeForbiddenNotice() {
    final pending = _forbiddenNotice;
    _forbiddenNotice = false;
    return pending;
  }

  void _runCleanups() {
    for (final cleanup in _cleanups) {
      cleanup();
    }
  }

  void _setUnauthenticated() {
    _session = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }
}
