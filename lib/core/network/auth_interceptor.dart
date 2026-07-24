import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/auth_event_bus.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // SECTION 1: Standardize on 'digipe_jwt' key
    final token = await _storage.read(key: 'digipe_jwt');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // SECTION 1: Log Scrubbing in debug only
    if (kDebugMode) {
      final maskedHeaders = Map<String, dynamic>.from(options.headers);
      if (maskedHeaders.containsKey('Authorization')) {
        maskedHeaders['Authorization'] = 'Bearer [SCRUBBED]';
      }
      debugPrint('[REQ] ${options.method} ${options.uri} headers: $maskedHeaders');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // SECTION 1: Global auth-expired event
      await _storage.delete(key: 'digipe_jwt');
      await _storage.delete(key: 'digipe_user');
      
      AuthEventBus.instance.add(AuthEvent.tokenExpired);
    }
    handler.next(err);
  }
}
