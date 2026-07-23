import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

// Fired when user wants to switch from phone login to email login
class SwitchToEmailLoginRequested extends AuthEvent {
  final String email;
  SwitchToEmailLoginRequested(this.email);
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
class AuthOnboardingCompleted extends AuthEvent {}

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
  final String verificationIdentifier;
  final String phoneNumber;
  final int attemptsLeft;
  final String? pendingName;
  final String? pendingEmail;
  final String mode; // 'login' or 'register'

  AwaitingOtp({
    required this.verificationIdentifier,
    required this.phoneNumber,
    required this.mode,
    this.attemptsLeft = 5,
    this.pendingName,
    this.pendingEmail,
  });
}
class Verifying extends AuthState {}
class Authenticated extends AuthState {
  final AuthUser user;
  Authenticated(this.user);
}
class AuthUserNotFound extends AuthState {
  final String phone;
  final String message;
  // If non-null, this user was email-registered; guide them to use this email
  final String? registeredEmail;
  AuthUserNotFound(this.phone, {this.message = "User not registered. Please register first.", this.registeredEmail});
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
class AuthSkipped extends AuthState {}
class AuthOnboarding extends AuthState {}

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
    on<SwitchToEmailLoginRequested>(_onSwitchToEmailLogin);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);

    _eventBusSub = bus.AuthEventBus.instance.stream.listen((busEvent) {
      if (busEvent == bus.AuthEvent.tokenExpired) {
        add(AuthTokenExpired());
      }
    });
  }

  Future<void> _onAuthCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    // STEP 1: Onboarding gate — checked first, always.
    final hasSeenOnboarding = await _storage.read(key: 'digipe_onboarding_seen');
    if (hasSeenOnboarding != 'true') {
      emit(AuthOnboarding());
      return;
    }

    // STEP 2: Existing token/user check — only reached once onboarding
    // has been confirmed as already completed.
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

  Future<void> _onOnboardingCompleted(AuthOnboardingCompleted event, Emitter<AuthState> emit) async {
    // Write must be awaited and confirmed BEFORE emitting AuthIdle
    await _storage.write(key: 'digipe_onboarding_seen', value: 'true');
    // Once written, AuthIdle will trigger Signup screen on main layout switch. 
    // Wait, what if the user actually has a valid token?
    // According to instructions, emit AuthIdle. If they somehow had a token, 
    // a subsequent AuthCheckRequested would log them in, but typically they don't.
    // Let's just emit AuthIdle to trigger signup screen as instructed.
    emit(AuthIdle());
  }

  Future<void> _onSendOtp(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(OtpSending());
    try {
      // Always format with country code for the backend
      final formattedPhone = AuthUtils.formatWithCountryCode(event.phone);

      debugPrint('[AuthBloc] Requesting OTP for login: $formattedPhone');
      final serverIdentifier = await _authRepository.requestOtp(formattedPhone);

      emit(AwaitingOtp(
        verificationIdentifier: serverIdentifier.isNotEmpty ? serverIdentifier : formattedPhone,
        phoneNumber: formattedPhone,
        mode: 'login',
      ));
    } on UserNotFoundException catch (e) {
      emit(AuthUserNotFound(
        event.phone,
        message: e.message,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(OtpSending());
    try {
      final rawPhone = AuthUtils.rawTenDigits(event.phone);
      final cleanEmail = event.email.trim().toLowerCase();
      final formattedPhone = AuthUtils.formatWithCountryCode(rawPhone);

      debugPrint('[AuthBloc] Registering user phone: $rawPhone, email: $cleanEmail');

      await _authRepository.register(
        fullName: event.fullName.trim(),
        phone: rawPhone,
        email: cleanEmail,
      );

      // Backend now sends OTP to the phone number after registration.
      // Use phone as verificationIdentifier for OTP verification.
      debugPrint('[AuthBloc] Registration successful. OTP sent to phone: $formattedPhone');

      emit(AwaitingOtp(
        verificationIdentifier: formattedPhone,
        phoneNumber: formattedPhone,
        mode: 'register',
        pendingName: event.fullName.trim(),
        pendingEmail: cleanEmail,
      ));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final serverData = e.response?.data;
      String? serverMsg;
      if (serverData is Map) {
        serverMsg = serverData['message']?.toString();
      }
      if (status == 409) {
        emit(AuthError(serverMsg ?? 'Already registered. Please login instead.'));
      } else {
        emit(AuthError(serverMsg ?? 'Failed to register.'));
      }
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpRequested event, Emitter<AuthState> emit) async {
    if (state is! AwaitingOtp) return;
    final currentState = state as AwaitingOtp;

    emit(Verifying());
    try {
      // Backend now always expects mobileNumber for verification
      final phoneToSend = AuthUtils.formatWithCountryCode(currentState.phoneNumber);

      debugPrint('[AuthBloc] Verifying OTP payload -> mobileNumber: $phoneToSend, code: ${event.code}');

      final result = await _authRepository.login(
        code: event.code,
        phone: phoneToSend,
        email: currentState.pendingEmail, // Pass email for user creation in backend
      );

      debugPrint('[AuthBloc] Verification successful');

      AuthUser user = result.user;

      if (currentState.pendingName != null || currentState.pendingEmail != null) {
        user = user.copyWith(
          name: currentState.pendingName ?? user.name,
          email: currentState.pendingEmail ?? user.email,
        );
      }

      await _storage.write(key: 'digipe_jwt', value: result.token);
      await _storage.write(key: 'digipe_user', value: jsonEncode(user.toJson()));

      emit(Authenticated(user));
    } catch (e) {
      debugPrint('[AuthBloc] Verification failed: $e');
      final newAttempts = currentState.attemptsLeft - 1;
      if (newAttempts <= 0) {
        emit(AuthError("Too many failed attempts. Please request a new OTP."));
      } else {
        emit(AwaitingOtp(
          verificationIdentifier: currentState.verificationIdentifier,
          phoneNumber: currentState.phoneNumber,
          mode: currentState.mode,
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
    // Note: phone→email mappings are intentionally kept across logouts
    // so the "use email" guidance still shows on re-login attempts.

    emit(AuthIdle());
  }

  // When user has a phone→email account (email-registered via app),
  // let them tap "Login with email" to pre-fill the email and send OTP.
  Future<void> _onSwitchToEmailLogin(SwitchToEmailLoginRequested event, Emitter<AuthState> emit) async {
    emit(OtpSending());
    try {
      final cleanEmail = event.email.trim().toLowerCase();
      debugPrint('[AuthBloc] Switching to email login: $cleanEmail');
      final serverIdentifier = await _authRepository.requestOtp(cleanEmail);
      emit(AwaitingOtp(
        verificationIdentifier: serverIdentifier.isNotEmpty ? serverIdentifier : cleanEmail,
        phoneNumber: cleanEmail, // phoneNumber field used for display/resend
        mode: 'login',
      ));
    } on UserNotFoundException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
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