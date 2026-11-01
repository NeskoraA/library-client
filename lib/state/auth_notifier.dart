import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/config.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'permissions.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUserId = 'auth_user_id';
  static const _kUsername = 'auth_username';
  static const _kFullName = 'auth_full_name';
  static const _kRole = 'auth_role';
  static const _kReaderId = 'auth_reader_id';
  static const _kLoginAt = 'auth_login_at';
  static const _kLastActivity = 'auth_last_activity';

  final SharedPreferences _prefs;
  late AuthRepository api;

  AuthNotifier(this._prefs);

  AppUser? _user;
  String? _accessToken;
  String? logoutReason;
  Future<bool>? _refreshing;
  DateTime _lastSavedActivity = DateTime.fromMillisecondsSinceEpoch(0);

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;

  bool can(Permission permission) => roleCan(_user?.role, permission);

  DateTime? get loginAt => _readTime(_kLoginAt);

  DateTime? _readTime(String key) {
    final ms = _prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    if (access == null) return;
    _accessToken = access;

    final now = DateTime.now();
    final started = _readTime(_kLoginAt);
    final lastActivity = _readTime(_kLastActivity);
    if (started != null && now.difference(started) > sessionMaxDuration) {
      await logout(reason: 'Время сеанса истекло, войдите снова.');
      return;
    }
    if (lastActivity != null &&
        now.difference(lastActivity) > inactivityTimeout) {
      await logout(reason: 'Сеанс завершён из-за отсутствия активности.');
      return;
    }

    final role = _prefs.getString(_kRole);
    if (role != null) {
      _user = AppUser(
        id: _prefs.getInt(_kUserId) ?? 0,
        username: _prefs.getString(_kUsername) ?? '',
        fullName: _prefs.getString(_kFullName) ?? '',
        role: Role.fromName(role),
        readerId: _prefs.getInt(_kReaderId),
      );
    } else {
      try {
        await _saveUser(await api.me());
      } on UnauthorizedException {
        await logout();
      } on ApiException {
        return;
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await api.login(username, password);
    logoutReason = null;
    await _saveTokens(result);
    await _saveUser(result.user);
    await _prefs.setInt(_kLoginAt, DateTime.now().millisecondsSinceEpoch);
    await touchActivity(force: true);
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) => api.register(
    username: username,
    password: password,
    email: email,
    fullName: fullName,
  );

  Future<bool> refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refresh = _prefs.getString(_kRefresh);
    if (refresh == null) {
      await logout(reason: 'Сеанс истёк, войдите снова.');
      return false;
    }
    try {
      final result = await api.refresh(refresh);
      await _saveTokens(result);
      return true;
    } on ApiException {
      await logout(reason: 'Не удалось продлить сеанс, войдите снова.');
      return false;
    }
  }

  Future<void> logout({String? reason}) async {
    final refresh = _prefs.getString(_kRefresh);
    final wasAuthenticated = _user != null || _accessToken != null;
    _user = null;
    _accessToken = null;
    for (final key in [
      _kAccess,
      _kRefresh,
      _kUserId,
      _kUsername,
      _kFullName,
      _kRole,
      _kReaderId,
      _kLoginAt,
      _kLastActivity,
    ]) {
      await _prefs.remove(key);
    }
    if (reason != null) logoutReason = reason;
    if (refresh != null) {
      api.logout(refresh).catchError((_) {});
    }
    if (wasAuthenticated || reason != null) notifyListeners();
  }

  Future<void> touchActivity({bool force = false}) async {
    final now = DateTime.now();
    if (!force && now.difference(_lastSavedActivity).inSeconds < 5) return;
    _lastSavedActivity = now;
    await _prefs.setInt(_kLastActivity, now.millisecondsSinceEpoch);
  }

  Future<void> _saveTokens(AuthResult result) async {
    _accessToken = result.accessToken;
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
  }

  Future<void> _saveUser(AppUser user) async {
    _user = user;
    await _prefs.setInt(_kUserId, user.id);
    await _prefs.setString(_kUsername, user.username);
    await _prefs.setString(_kFullName, user.fullName);
    await _prefs.setString(_kRole, user.role.name);
    if (user.readerId != null) {
      await _prefs.setInt(_kReaderId, user.readerId!);
    } else {
      await _prefs.remove(_kReaderId);
    }
  }
}
