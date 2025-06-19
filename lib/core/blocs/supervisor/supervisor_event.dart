import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:supervisor_wo/models/user_profile.dart';

/// Base class for all SupervisorBloc events
@immutable
sealed class SupervisorEvent extends Equatable {
  /// Creates a new SupervisorEvent
  const SupervisorEvent();

  @override
  List<Object> get props => [];
}

/// Event to load the supervisor profile data
class SupervisorStarted extends SupervisorEvent {
  /// Creates a new SupervisorStarted event
  const SupervisorStarted();
}

/// Event to refresh the supervisor profile data
class SupervisorRefreshed extends SupervisorEvent {
  /// Creates a new SupervisorRefreshed event
  const SupervisorRefreshed();
}

/// Event to update the supervisor profile data
class SupervisorProfileUpdated extends SupervisorEvent {
  /// The updated user profile
  final UserProfile profile;

  /// Creates a new SupervisorProfileUpdated event
  const SupervisorProfileUpdated(this.profile);

  @override
  List<Object> get props => [profile];
}
