import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionService {
  static const _storage = FlutterSecureStorage();
  static const _idTokenKey = 'shadowtrace_id_token';
  static const _refreshTokenKey = 'shadowtrace_refresh_token';
  static const _userIdKey = 'shadowtrace_user_id';
  static const _accessTokenKey = 'shadowtrace_access_token';
  static const _guestKey = 'shadowtrace_is_guest';

  Future<void> saveSession({
    required String userId,
    String? idToken,
    String? refreshToken,
    String? accessToken,
    bool isGuest = false,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    if (idToken != null) await _storage.write(key: _idTokenKey, value: idToken);
    if (refreshToken != null) await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (accessToken != null) await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _guestKey, value: isGuest.toString());
  }

  Future<String?> readUserId() => _storage.read(key: _userIdKey);
  Future<String?> readIdToken() => _storage.read(key: _idTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<bool> isGuest() async => (await _storage.read(key: _guestKey)) == 'true';

  Future<bool> hasSession() async {
    final userId = await readUserId();
    return userId != null && userId.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _guestKey);
  }
}
