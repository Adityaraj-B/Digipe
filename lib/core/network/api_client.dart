import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(_storage),
      if (kDebugMode)
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          logPrint: (object) {
            // Scrub Authorization header from debug logs for safety
            final log = object.toString();
            if (log.contains('Authorization: Bearer')) {
              debugPrint(log.replaceAll(RegExp(r'Bearer\s+[^\s]+'), 'Bearer [SCRUBBED]'));
            } else {
              debugPrint(log);
            }
          },
        ),
    ]);
  }

  // Helper for multipart uploads
  Future<Response> upload(String path, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    return dio.post(path, data: formData);
  }
}
