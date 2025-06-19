import 'package:equatable/equatable.dart';

/// Base class for all completion rate events
sealed class CompletionRateEvent extends Equatable {
  /// Creates a new CompletionRateEvent
  const CompletionRateEvent();

  @override
  List<Object> get props => [];
}

/// Event to start the completion rate screen
class CompletionRateStarted extends CompletionRateEvent {
  /// Creates a new CompletionRateStarted event
  const CompletionRateStarted();
}

/// Event to refresh the completion rate data
class CompletionRateRefreshed extends CompletionRateEvent {
  /// Creates a new CompletionRateRefreshed event
  const CompletionRateRefreshed();
}
