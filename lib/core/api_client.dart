import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<bool> Function()? onUnauthorized,
  Duration retryDelay = const Duration(milliseconds: 400),
  int maxAttempts = 3,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        _log(response.requestOptions, status);
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        if (error.response == null) {
          _log(options, null, error.type.name);
        } else if ((error.response!.statusCode ?? 0) >= 500) {
          _log(options, error.response!.statusCode);
        }

        if (error.response?.statusCode == 401 &&
            onUnauthorized != null &&
            options.extra['authRetried'] != true &&
            !options.path.startsWith('/auth/')) {
          if (await onUnauthorized()) {
            options.extra['authRetried'] = true;
            try {
              return handler.resolve(await dio.fetch(options));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }

        final attempt = (options.extra['attempt'] as int?) ?? 1;
        if (_isRetryable(error) && attempt < maxAttempts) {
          await Future.delayed(retryDelay * attempt);
          options.extra['attempt'] = attempt + 1;
          try {
            return handler.resolve(await dio.fetch(options));
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}

bool _isRetryable(DioException error) {
  final isRead = error.requestOptions.method.toUpperCase() == 'GET';
  final isNetworkFailure = switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };
  return isRead && isNetworkFailure;
}

void _log(RequestOptions options, int? status, [String? failure]) {
  if (!kDebugMode) return;
  final attempt = options.extra['attempt'];
  debugPrint(
    '[API] ${options.method} ${options.uri} -> ${status ?? failure}'
    '${attempt != null ? ' (попытка $attempt)' : ''}',
  );
}
