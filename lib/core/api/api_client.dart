import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl, String? token}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    if (kDebugMode) {
      // Keep debug networking useful without printing credentials, passwords,
      // OAuth tokens, reset codes, or response payloads containing user data.
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
      ));
    }
  }

  void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _requestWithRedirectRetry(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
  }) async {
    return _requestWithRedirectRetry(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      contentType: contentType,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
  }) async {
    return _requestWithRedirectRetry(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      contentType: contentType,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
  }) async {
    return _requestWithRedirectRetry(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      contentType: contentType,
    );
  }

  Future<Response> _requestWithRedirectRetry({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? contentType,
  }) async {
    try {
      return await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, contentType: contentType),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final location = error.response?.headers.value(HttpHeaders.locationHeader);

      if ((statusCode == 301 || statusCode == 302 || statusCode == 307 || statusCode == 308) &&
          location != null &&
          location.isNotEmpty) {
        final redirectUri = _resolveRedirectUri(
          location,
          queryParameters: queryParameters,
        );

        if (!_isTrustedRedirect(redirectUri)) {
          throw DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: DioExceptionType.badResponse,
            error: 'Refusing to forward an authenticated request to an untrusted redirect.',
          );
        }

        return _dio.requestUri(
          redirectUri,
          data: data,
          options: Options(method: method, contentType: contentType),
        );
      }

      rethrow;
    }
  }

  bool _isTrustedRedirect(Uri redirectUri) {
    final baseUri = Uri.parse(_dio.options.baseUrl);
    return redirectUri.scheme == baseUri.scheme &&
        redirectUri.host == baseUri.host &&
        redirectUri.port == baseUri.port;
  }

  Uri _resolveRedirectUri(
    String location, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedBaseUrl = _dio.options.baseUrl.endsWith('/')
        ? _dio.options.baseUrl
        : '${_dio.options.baseUrl}/';
    final baseUri = Uri.parse(normalizedBaseUrl);
    final resolvedUri = baseUri.resolve(location);

    if (queryParameters == null || queryParameters.isEmpty) {
      return resolvedUri;
    }

    final mergedQueryParameters = <String, dynamic>{
      ...resolvedUri.queryParameters,
      ...queryParameters,
    };

    return resolvedUri.replace(
      queryParameters: mergedQueryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }
}
