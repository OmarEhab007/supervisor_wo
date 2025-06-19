import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:supervisor_wo/models/user_profile.dart';

/// Status of the authentication process
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

/// State for the authentication bloc
@immutable
class AuthState extends Equatable {
  /// Current status of the authentication process
  final AuthStatus status;
  
  /// User profile if authenticated
  final UserProfile? userProfile;
  
  /// Error message if any
  final String? errorMessage;

  /// Creates an instance of [AuthState]
  const AuthState({
    this.status = AuthStatus.initial,
    this.userProfile,
    this.errorMessage,
  });

  /// Initial state for the authentication bloc
  factory AuthState.initial() => const AuthState();

  /// Creates a copy of this state with the given fields replaced
  AuthState copyWith({
    AuthStatus? status,
    UserProfile? userProfile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage,
    );
  }

  /// Whether the user is authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Whether the authentication process is loading
  bool get isLoading => status == AuthStatus.loading;

  @override
  List<Object?> get props => [status, userProfile, errorMessage];
}
