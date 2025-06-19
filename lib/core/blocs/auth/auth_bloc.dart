import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/auth/auth_event.dart';
import 'package:supervisor_wo/core/blocs/auth/auth_state.dart';
import 'package:supervisor_wo/core/repositories/auth_repository.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/core/services/fcm_service.dart';
import 'package:supervisor_wo/models/user_profile.dart';

/// BLoC for handling authentication operations
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  /// Creates an instance of [AuthBloc]
  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(AuthState.initial()) {
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<AuthSignedInWithEmail>(_onAuthSignedInWithEmail);
    on<AuthSignedUpWithEmail>(_onAuthSignedUpWithEmail);
    on<AuthSignedOut>(_onAuthSignedOut);
    on<AuthErrorCleared>(_onAuthErrorCleared);
  }

  /// Handles the [AuthStatusChecked] event
  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      final currentUser = SupabaseClientWrapper.client.auth.currentUser;
      if (currentUser != null) {
        final userProfile = await _authRepository.getUserProfile();
        
        // Update FCM token for the authenticated user
        await FCMService.instance.updateTokenForUser(currentUser.id);
        
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          userProfile: userProfile,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handles the [AuthSignedInWithEmail] event
  Future<void> _onAuthSignedInWithEmail(
    AuthSignedInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );

      final userProfile = await _authRepository.getUserProfile();

      // Update FCM token for the newly signed-in user
      final currentUser = SupabaseClientWrapper.client.auth.currentUser;
      if (currentUser != null) {
        await FCMService.instance.updateTokenForUser(currentUser.id);
      }

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: userProfile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handles the [AuthSignedUpWithEmail] event
  Future<void> _onAuthSignedUpWithEmail(
    AuthSignedUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      // Create a timestamp for consistency
      final now = DateTime.now();

      // Create a user profile with default values for optional fields
      final userProfile = UserProfile(
        id: '', // Will be set by Supabase
        username: event.username,
        email: event.email,
        phone: event.phone,
        plateNumbers: event.plateNumbers ?? '',
        plateEnglishLetters: event.plateLetters ??
            '', // Using plateLetters from event as plateEnglishLetters
        plateArabicLetters:
            event.plateArabicLetters ?? '', // Use plateArabicLetters from event
        iqamaId: event.iqamaId ?? '',
        workId: event.workId ?? '',
        createdAt: now,
        updatedAt: now, // Set initial updatedAt to match createdAt
      );

      // Pass all profile data to the repository
      await _authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        username: event.username,
        phone: event.phone,
        plateNumbers: event.plateNumbers,
        plateLetters: event.plateLetters,
        plateArabicLetters: event.plateArabicLetters,
        iqamaId: event.iqamaId,
        workId: event.workId,
      );

      // Update FCM token for the newly signed-up user
      final currentUser = SupabaseClientWrapper.client.auth.currentUser;
      if (currentUser != null) {
        await FCMService.instance.updateTokenForUser(currentUser.id);
      }

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userProfile: userProfile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handles the [AuthSignedOut] event
  Future<void> _onAuthSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      await _authRepository.signOut();

      // Clear FCM token association when user signs out
      await FCMService.instance.updateTokenForUser(null);

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        userProfile: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handles the [AuthErrorCleared] event
  void _onAuthErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }
}
