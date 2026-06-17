import 'dart:async';
import 'dart:convert';
import '../bloc/auth_bloc.dart';

class AuthRepository {
  static const String loginUrl = "https://auth.surefy.co/api/v1/auth/login";

  Future<UserModel> login(String phone, String otp) async {
    // Note: User reported 404 for this route currently.
    // We implement the structure so it's ready when the API is fixed.
    
    // For now, we simulate a successful login with mock data 
    // to keep the app functional while the user fixes the backend.
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock response matching the desired dynamic behavior
    return UserModel(
      name: 'Adityaraj',
      email: 'adityaraj@surefy.co',
      phone: phone,
      address: 'Surefy HQ, Digital City',
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
