import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../utils/auth_utils.dart';
import '../utils/auth_event_bus.dart' as bus;

// --- Events ---
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class SendOtpRequested extends AuthEvent {
  final String phone;
  SendOtpRequested(this.phone);
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String email;
  RegisterRequested({required this.fullName, required this.phone, required this.email});
}

class VerifyOtpRequested extends AuthEvent {
  final String code;
  VerifyOtpRequested(this.code);
}

class AuthSetDevToken extends AuthEvent {
  final String token;
  AuthSetDevToken(this.token);
}

class AuthSkipRequested extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}
class AuthTokenExpired extends AuthEvent {}

// --- States ---
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthIdle extends AuthState {}
class OtpSending extends AuthState {}
class AwaitingOtp extends AuthState {
  final String identifier; // normalized phone
  final int attemptsLeft;
  AwaitingOtp(this.identifier, {this.attemptsLeft = 5});
}
class Verifying extends AuthState {}
class Authenticated extends AuthState {
  final AuthUser user;
  Authenticated(this.user);
}
class AuthUserNotFound extends AuthState {
  final String phone;
  final String message;
  AuthUserNotFound(this.phone, {this.message = "User not registered. Please register first."});
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
class AuthSkipped extends AuthState {}

// --- BLoC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StreamSubscription? _eventBusSub;

  AuthBloc({required ApiService apiService})
      : _apiService = apiService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheck);
    on<SendOtpRequested>(_onSendOtp);
    on<RegisterRequested>(_onRegister);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<AuthSetDevToken>(_onSetDevToken);
    on<AuthSkipRequested>((event, emit) => emit(AuthSkipped()));
    on<AuthLogoutRequested>(_onLogout);
    on<AuthTokenExpired>((event, emit) => emit(AuthIdle()));

    // SECTION 1: Listen to global auth-expired event
    _eventBusSub = bus.AuthEventBus.instance.stream.listen((busEvent) {
      if (busEvent == bus.AuthEvent.tokenExpired) {
        add(AuthTokenExpired());
      }
    });
  }

  Future<void> _onAuthCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final token = await _storage.read(key: 'digipe_jwt');
    final userJson = await _storage.read(key: 'digipe_user');

    if (token != null && token.isNotEmpty && userJson != null) {
      try {
        final user = AuthUser.fromJson(jsonDecode(userJson));
        emit(Authenticated(user));
      } catch (_) {
        await _storage.delete(key: 'digipe_jwt');
        await _storage.delete(key: 'digipe_user');
        emit(AuthIdle());
      }
    } else {
      emit(AuthIdle());
    }
  }

  Future<void> _onSendOtp(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(OtpSending());
    try {
      final normalized = AuthUtils.normalizePhoneNumber(event.phone);
      await _apiService.sendOtp(normalized);
      emit(AwaitingOtp(normalized));
    } on UserNotFoundException catch (e) {
      emit(AuthUserNotFound(event.phone, message: e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(OtpSending());
    try {
      final rawDigits = event.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final data = await _apiService.register(fullName: event.fullName, phone: rawDigits, email: event.email);
      final serverIdentifier = data['identifier']?.toString() ?? rawDigits;
      emit(AwaitingOtp(serverIdentifier));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpRequested event, Emitter<AuthState> emit) async {
    if (state is! AwaitingOtp) return;
    final currentState = state as AwaitingOtp;
    
    emit(Verifying());
    try {
      final data = await _apiService.verifyOtp(currentState.identifier, event.code);
      final token = data['token'];
      final user = AuthUser.fromJson(data['user']);
      
      // SECTION 1: Fix the Auth Interceptor (Write Side matching digipe_jwt)
      await _storage.write(key: 'digipe_jwt', value: token);
      await _storage.write(key: 'digipe_user', value: jsonEncode(data['user']));
      
      emit(Authenticated(user));
    } catch (e) {
      final newAttempts = currentState.attemptsLeft - 1;
      if (newAttempts <= 0) {
        emit(AuthError("Too many failed attempts. Please request a new OTP."));
      } else {
        emit(AwaitingOtp(currentState.identifier, attemptsLeft: newAttempts));
      }
    }
  }

  Future<void> _onSetDevToken(AuthSetDevToken event, Emitter<AuthState> emit) async {
    emit(Verifying());
    try {
      await _storage.write(key: 'digipe_jwt', value: event.token);
      final devUser = AuthUser(id: 'dev', name: 'Dev User', email: 'dev@digipe.in', phone: '0000000000', role: 'admin');
      await _storage.write(key: 'digipe_user', value: jsonEncode({
        'id': devUser.id,
        'name': devUser.name,
        'email': devUser.email,
        'mobileNumber': devUser.phone,
        'role': devUser.role,
      }));
      emit(Authenticated(devUser));
    } catch (e) {
      emit(AuthError("Failed to set dev token"));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _storage.delete(key: 'digipe_jwt');
    await _storage.delete(key: 'digipe_user');
    await _storage.delete(key: 'digipe_cached_orders');
    await _storage.delete(key: 'digipe_cached_policies');
    
    emit(AuthIdle());
  }

  @override
  Future<void> close() {
    _eventBusSub?.cancel();
    return super.close();
  }
}
