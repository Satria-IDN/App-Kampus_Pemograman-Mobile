import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyRole = 'user_role';
  static const _keyName = 'user_name';

  static Future<void> saveSession({
    required String userId,
    required String role,
    required String name,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyName, value: name);
    await _storage.write(key: _keyToken, value: 'token_${DateTime.now().millisecondsSinceEpoch}');
  }

  static Future<Map<String, String?>> getSession() async {
    return {
      'userId': await _storage.read(key: _keyUserId),
      'role': await _storage.read(key: _keyRole),
      'name': await _storage.read(key: _keyName),
      'token': await _storage.read(key: _keyToken),
    };
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}