import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/utils/auth_event_bus.dart' as bus;

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

class AuthUpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? email;
  final String? house;
  final String? area;
  final String? city;
  final String? state;
  final String? pin;

  AuthUpdateProfileRequested({
    this.name,
    this.email,
    this.house,
    this.area,
    this.city,
    this.state,
    this.pin,
  });
}

// --- States ---
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthIdle extends AuthState {}
class OtpSending extends AuthState {}
class AwaitingOtp extends AuthState {
  final String identifier; // normalized phone
  final int attemptsLeft;
  final String? pendingName;
  final String? pendingEmail;

  AwaitingOtp(this.identifier, {this.attemptsLeft = 5, this.pendingName, this.pendingEmail});
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
  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StreamSubscription? _eventBusSub;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheck);
    on<SendOtpRequested>(_onSendOtp);
    on<RegisterRequested>(_onRegister);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<AuthSetDevToken>(_onSetDevToken);
    on<AuthSkipRequested>((event, emit) => emit(AuthSkipped()));
    on<AuthLogoutRequested>(_onLogout);
    on<AuthTokenExpired>((event, emit) => emit(AuthIdle()));
    on<AuthUpdateProfileRequested>(_onUpdateProfile);

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
      await _authRepository.requestOtp(normalized);
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
      
      await _authRepository.register(
          fullName: event.fullName, phone: rawDigits, email: event.email);
      
      final normalized = AuthUtils.normalizePhoneNumber(rawDigits);
                               
      emit(AwaitingOtp(normalized,
          pendingName: event.fullName, pendingEmail: event.email));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final serverData = e.response?.data;
      
      String? serverMsg;
      if (serverData is Map) {
        serverMsg = serverData['message']?.toString();
      }

      if (status == 409) {
        emit(AuthError(serverMsg ?? 'This number is already registered. Please log in instead.'));
      } else {
        // If the backend returns "User not found" even here, we show it clearly
        emit(AuthError(serverMsg ?? 'Registration failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyOtp(
      VerifyOtpRequested event, Emitter<AuthState> emit) async {
    if (state is! AwaitingOtp) return;
    final currentState = state as AwaitingOtp;

    emit(Verifying());
    try {
      final normalizedIdentifier =
      AuthUtils.normalizePhoneNumber(currentState.identifier);
      final result = await _authRepository.login(normalizedIdentifier, event.code);

      AuthUser user = result.user;

      // If we have pending registration details that weren't yet reflected in the login response,
      // override them here so the profile UI is instantly updated.
      if (currentState.pendingName != null || currentState.pendingEmail != null) {
        user = user.copyWith(
          name: currentState.pendingName ?? user.name,
          email: currentState.pendingEmail ?? user.email,
        );
      }

      // SECTION 1: Fix the Auth Interceptor (Write Side matching digipe_jwt)
      await _storage.write(key: 'digipe_jwt', value: result.token);
      await _storage.write(key: 'digipe_user', value: jsonEncode(user.toJson()));

      emit(Authenticated(user));
    } catch (e) {
      final newAttempts = currentState.attemptsLeft - 1;
      if (newAttempts <= 0) {
        emit(AuthError("Too many failed attempts. Please request a new OTP."));
      } else {
        emit(AwaitingOtp(
          currentState.identifier,
          attemptsLeft: newAttempts,
          pendingName: currentState.pendingName,
          pendingEmail: currentState.pendingEmail,
        ));
      }
    }
  }

  Future<void> _onSetDevToken(AuthSetDevToken event, Emitter<AuthState> emit) async {
    emit(Verifying());
    try {
      await _storage.write(key: 'digipe_jwt', value: event.token);
      final devUser = AuthUser(id: 'dev', name: 'Dev User', email: 'dev@digipe.in', phone: '0000000000', role: 'admin');
      await _storage.write(key: 'digipe_user', value: jsonEncode(devUser.toJson()));
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

  Future<void> _onUpdateProfile(AuthUpdateProfileRequested event, Emitter<AuthState> emit) async {
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      final updatedUser = currentUser.copyWith(
        name: event.name,
        email: event.email,
        house: event.house,
        area: event.area,
        city: event.city,
        state: event.state,
        pin: event.pin,
      );
      
      // Persist the updated user object
      await _storage.write(key: 'digipe_user', value: jsonEncode(updatedUser.toJson()));
      
      emit(Authenticated(updatedUser));
    }
  }

  @override
  Future<void> close() {
    _eventBusSub?.cancel();
    return super.close();
  }
}
