import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../models/api_models.dart';

class SurefyLoginResult {
  final String token;
  final AuthUser user;

  const SurefyLoginResult({
    required this.token,
    required this.user,
  });
}

class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException({this.message = 'User not registered. Please register first.'});
}

class AuthRepository {
  static const String _baseUrl = 'https://api.digipe.in/api';
  static const String _apiKey = 'di_live_8a3bab71513c47c73023b3e66fcec29b0679dc7891a30ed7';

  late final Dio _client = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': _apiKey,
      },
    ),
  );

  // MATCH THE WEBSITE: Accept both phone and email dynamically
  Future<SurefyLoginResult> login({
    required String code,
    String? phone,
    String? email,
  }) async {
    dev.log('Attempting verify-otp with phone: $phone, email: $email', name: 'AuthRepository');

    // Build payload exactly how the backend expects it
    final data = <String, dynamic>{
      'code': code,
    };
    if (phone != null && phone.isNotEmpty) data['mobileNumber'] = phone;
    if (email != null && email.isNotEmpty) data['email'] = email;

    final response = await _client.post(
      '/auth/verify-otp',
      data: data,
    );

    dev.log('verify-otp raw response: ${response.data}', name: 'AuthRepository');

    final payload = _unwrapData(response.data);
    final token = _extractToken(payload);
    final userJson = _extractUser(payload);

    if (token.isEmpty) {
      throw const FormatException('Login response did not include a token');
    }

    return SurefyLoginResult(
      token: token,
      user: AuthUser.fromJson(userJson),
    );
  }

  Future<String> requestOtp(String phone) async {
    dev.log('Requesting OTP for: $phone', name: 'AuthRepository');
    try {
      final response = await _client.post(
        '/auth/send-otp',
        data: {
          'mobileNumber': phone,
        },
      );
      dev.log('send-otp raw response: ${response.data}', name: 'AuthRepository');

      final payload = _unwrapData(response.data);
      final identifier = _extractIdentifier(payload);
      return identifier.isNotEmpty ? identifier : phone;
    } on DioException catch (e) {
      dev.log('requestOtp DioError: ${e.response?.statusCode}, ${e.response?.data}', name: 'AuthRepository');
      if (e.response?.statusCode == 404 ||
          (e.response?.data is Map && e.response?.data['message']?.toString().contains('not found') == true)) {
        throw UserNotFoundException();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
  }) async {
    dev.log('Registering user: $fullName, $phone, $email', name: 'AuthRepository');
    final response = await _client.post(
      '/auth/register',
      data: {
        'fullName': fullName,
        'phone': phone,
        'email': email,
      },
    );
    dev.log('register raw response: ${response.data}', name: 'AuthRepository');
    return _unwrapData(response.data);
  }

  Future<void> logout() async {}

  Map<String, dynamic> _unwrapData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      return map;
    }
    throw const FormatException('Unexpected auth response');
  }

  String _extractToken(Map<String, dynamic> data) {
    final candidates = [
      data['token'],
      data['accessToken'],
      data['jwt'],
      data['authToken'],
      data['data'] is Map ? (data['data'] as Map)['token'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }

  String _extractIdentifier(Map<String, dynamic> data) {
    final candidates = [
      data['identifier'],
      data['sessionId'],
      data['requestId'],
      data['otpSessionId'],
      data['email'],
      data['phone'],
      data['mobileNumber'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> data) {
    final candidates = [
      data['user'],
      data['profile'],
      data['account'],
      data['data'] is Map ? (data['data'] as Map)['user'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate);
      }
    }
    return data;
  }
}