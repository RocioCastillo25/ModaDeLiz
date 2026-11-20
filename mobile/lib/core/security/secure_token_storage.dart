import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/session.dart';
import 'token_storage.dart';

/// Guarda la sesión en el almacenamiento seguro del dispositivo
/// (Keystore en Android, Keychain en iPhone). Nunca guarda la contraseña.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'checklizz_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(Session session) {
    return _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<Session?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Datos dañados o ilegibles: se descartan y se pide iniciar sesión.
      await clear();
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Sin acceso al almacenamiento no hay nada más que borrar.
    }
  }
}
