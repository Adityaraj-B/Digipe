import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';

class UserModel {
  final String name;
  final String email;
  final String phone;
  final String address;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });
}

abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String otp;
  AuthLoginRequested({required this.phone, required this.otp});
}

class AuthSkipRequested extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthSkipped extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthSkipRequested>((event, emit) => emit(AuthSkipped()));
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(event.phone, event.otp);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError("Login failed. Please try again."));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(AuthInitial());
  }
}
