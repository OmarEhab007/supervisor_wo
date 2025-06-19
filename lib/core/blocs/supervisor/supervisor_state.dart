import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:supervisor_wo/models/user_profile.dart';

/// Status enum for SupervisorState
enum SupervisorStatus {
  /// Initial state
  initial,

  /// Loading state
  loading,

  /// Success state
  success,

  /// Failure state
  failure,
}

/// State for the SupervisorBloc
@immutable
class SupervisorState extends Equatable {
  /// The current status of the supervisor data
  final SupervisorStatus status;

  /// The supervisor profile data
  final UserProfile? profile;

  /// Error message if any
  final String? errorMessage;

  /// Creates a new SupervisorState
  const SupervisorState({
    this.status = SupervisorStatus.initial,
    this.profile,
    this.errorMessage,
  });

  /// Creates a copy of this SupervisorState with the given fields replaced with new values
  SupervisorState copyWith({
    SupervisorStatus? status,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return SupervisorState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
