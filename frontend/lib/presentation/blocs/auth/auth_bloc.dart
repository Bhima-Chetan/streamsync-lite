import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/firebase_messaging_service.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/connectivity_service.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String name;
  final String password;
  AuthRegisterRequested(this.email, this.name, this.password);
  @override
  List<Object?> get props => [email, name, password];
}

class AuthLogoutRequested extends AuthEvent {}

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;
  final String name;
  AuthAuthenticated(this.userId, this.email, this.name);
  @override
  List<Object?> get props => [userId, email, name];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    if (_authRepository.isLoggedIn) {
      emit(AuthAuthenticated(
        _authRepository.userId!,
        _authRepository.userEmail ?? 'user@example.com',
        _authRepository.userName ?? 'User',
      ));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    print('🔵 AuthBloc._onLoginRequested called');
    emit(AuthLoading());
    print('🔵 AuthBloc: Emitted AuthLoading state');

    try {
      print('🔵 AuthBloc: Calling _authRepository.login...');
      final result = await _authRepository.login(event.email, event.password);
      print('🔵 AuthBloc: Login successful! Result: $result');
      print('🔵 AuthBloc: Emitting AuthAuthenticated state...');

      final userId = result['user']['id'];

      emit(AuthAuthenticated(
        userId,
        result['user']['email'],
        result['user']['name'],
      ));
      print('✅ AuthBloc: AuthAuthenticated state emitted!');

      // Register FCM token with backend after successful login
      try {
        print('🔔 AuthBloc: Registering FCM token with backend...');
        await FirebaseMessagingService.registerTokenWithBackend(userId);
        print('✅ AuthBloc: FCM token registered successfully');
      } catch (e) {
        print('⚠️ AuthBloc: Failed to register FCM token: $e');
        // Don't fail the login if FCM registration fails
      }

      // Start connectivity monitoring for sync
      try {
        final connectivityService = getIt<ConnectivityService>();
        connectivityService.startMonitoring(userId);
        print('✅ AuthBloc: Connectivity monitoring started');
      } catch (e) {
        print('⚠️ AuthBloc: Failed to start connectivity monitoring: $e');
      }
    } catch (e) {
      print('❌ AuthBloc: Login failed with error: $e');
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.register(
          event.email, event.name, event.password);
      emit(AuthAuthenticated(
        result['user']['id'],
        result['user']['email'],
        result['user']['name'],
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    // Stop connectivity monitoring
    try {
      final connectivityService = getIt<ConnectivityService>();
      connectivityService.stopMonitoring();
      print('✅ AuthBloc: Connectivity monitoring stopped');
    } catch (e) {
      print('⚠️ AuthBloc: Failed to stop connectivity monitoring: $e');
    }

    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
