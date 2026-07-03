import '../models/api_models.dart';

class AuthRepository {
  static const String loginUrl = "https://auth.surefy.co/api/v1/auth/login";

  Future<AuthUser> login(String phone, String otp) async {
    // Note: User reported 404 for this route currently.
    // We implement the structure so it's ready when the API is fixed.
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock response matching the desired dynamic behavior
    return AuthUser(
      id: 'mock_id',
      name: 'Adityaraj',
      email: 'adityaraj@surefy.co',
      phone: phone,
      role: 'user',
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
