import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/entity.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const AuthResult(this.accessToken, this.refreshToken, this.user);

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    readString(json['accessToken']),
    readString(json['refreshToken']),
    AppUser.fromJson(readMap(json['user'])),
  );
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResult> login(String username, String password) => guard(() async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return AuthResult.fromJson(readMap(response.data));
  });

  Future<AuthResult> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResult.fromJson(readMap(response.data));
  });

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) => guard(
    () => _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
      },
    ),
  );

  Future<AppUser> me() => guard(() async {
    final response = await _dio.get('/auth/me');
    return AppUser.fromJson(readMap(response.data));
  });

  Future<void> logout(String refreshToken) => guard(
    () => _dio.post('/auth/logout', data: {'refreshToken': refreshToken}),
  );

  Future<List<AppUser>> users() => guard(() async {
    final response = await _dio.get('/users', queryParameters: {'size': 100});
    return readMapList(
      readMap(response.data)['items'],
    ).map(AppUser.fromJson).toList();
  });
}
