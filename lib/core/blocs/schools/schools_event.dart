import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Base class for all SchoolsBloc events
@immutable
sealed class SchoolsEvent extends Equatable {
  /// Creates a new SchoolsEvent
  const SchoolsEvent();

  @override
  List<Object> get props => [];
}

/// Event to load the schools list
class SchoolsStarted extends SchoolsEvent {
  /// Creates a new SchoolsStarted event
  const SchoolsStarted();
}

/// Event to refresh the schools list
class SchoolsRefreshed extends SchoolsEvent {
  /// Creates a new SchoolsRefreshed event
  const SchoolsRefreshed();
}

/// Event when a school is selected
class SchoolSelected extends SchoolsEvent {
  /// The ID of the selected school
  final String schoolId;

  /// Creates a new SchoolSelected event
  const SchoolSelected(this.schoolId);

  @override
  List<Object> get props => [schoolId];
}

/// Event to filter schools by search query
class SchoolsSearchQueryChanged extends SchoolsEvent {
  /// The search query
  final String query;

  /// Creates a new SchoolsSearchQueryChanged event
  const SchoolsSearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

/// Event to filter schools by emergency status
class SchoolsEmergencyFilterToggled extends SchoolsEvent {
  /// Whether to show only schools with emergency reports
  final bool showOnlyEmergency;

  /// Creates a new SchoolsEmergencyFilterToggled event
  const SchoolsEmergencyFilterToggled(this.showOnlyEmergency);

  @override
  List<Object> get props => [showOnlyEmergency];
}
