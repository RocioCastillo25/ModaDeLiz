import 'package:flutter/foundation.dart';

import '../../data/models/app_role.dart';
import '../../data/repositories/auth_failure.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/connectivity_service.dart';
import 'session_view_model.dart';

/// Estado visible del inicio de sesión: cargando, éxito o error.
enum LoginStatus { idle, loading, success, error }

/// Tipos de error que puede mostrar el inicio de sesión.
enum LoginError {
  emptyFields,
  invalidCredentials,
  accountDisabled,
  noConnection,
  serviceUnavailable,
  incompleteData,
}

/// ViewModel de la pantalla de inicio de sesión. No conoce widgets.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository, this._connectivity, this._session);

  final AuthRepository _repository;
  final ConnectivityService _connectivity;
  final SessionViewModel _session;

  LoginStatus _status = LoginStatus.idle;
  LoginError? _error;
  bool _usernameMissing = false;
  bool _passwordMissing = false;
  bool _showAdminNotice = false;

  LoginStatus get status => _status;
  LoginError? get error => _error;
  bool get usernameMissing => _usernameMissing;
  bool get passwordMissing => _passwordMissing;

  /// `true` cuando un administrador entró: se le muestra el aviso hacia la web.
  bool get showAdminNotice => _showAdminNotice;

  /// El botón se deshabilita mientras hay una operación en curso.
  bool get canSubmit => _status != LoginStatus.loading;

  /// Intenta iniciar sesión. Ignora envíos mientras hay uno en curso.
  Future<void> submit(String username, String password) async {
    if (!canSubmit) return;

    final user = username.trim();
    _usernameMissing = user.isEmpty;
    _passwordMissing = password.trim().isEmpty;
    if (_usernameMissing || _passwordMissing) {
      _setError(LoginError.emptyFields);
      return;
    }

    _status = LoginStatus.loading;
    _error = null;
    notifyListeners();

    if (!await _connectivity.isOnline()) {
      _setError(LoginError.noConnection);
      return;
    }

    try {
      final session = await _repository.login(user, password);
      if (session.user.role == AppRole.admin) {
        // El administrador no entra a la app: se le avisa que use la web.
        _showAdminNotice = true;
        _status = LoginStatus.idle;
        notifyListeners();
        return;
      }
      _status = LoginStatus.success;
      notifyListeners();
      _session.onLoggedIn(session);
    } on AuthFailure catch (failure) {
      _setError(_mapFailure(failure.type));
    } catch (_) {
      _setError(LoginError.serviceUnavailable);
    }
  }

  /// Cierra el aviso del administrador y vuelve al formulario.
  void dismissAdminNotice() {
    _showAdminNotice = false;
    notifyListeners();
  }

  /// Limpia todo el estado (por ejemplo, al cerrar sesión).
  void reset() {
    _status = LoginStatus.idle;
    _error = null;
    _usernameMissing = false;
    _passwordMissing = false;
    _showAdminNotice = false;
    notifyListeners();
  }

  void _setError(LoginError error) {
    _status = LoginStatus.error;
    _error = error;
    notifyListeners();
  }

  LoginError _mapFailure(AuthFailureType type) {
    switch (type) {
      case AuthFailureType.invalidCredentials:
        return LoginError.invalidCredentials;
      case AuthFailureType.accountDisabled:
        return LoginError.accountDisabled;
      case AuthFailureType.incompleteData:
        return LoginError.incompleteData;
      case AuthFailureType.network:
        return LoginError.noConnection;
      case AuthFailureType.server:
        return LoginError.serviceUnavailable;
    }
  }
}
