import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';

/// Base class for all ReportsBloc events
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the initial data for the reports screen
class ReportsStarted extends ReportsEvent {
  const ReportsStarted();
}

class ReportsStatusCleared extends ReportsEvent {}

/// Event when the reports screen is refreshed
class ReportsRefreshed extends ReportsEvent {
  const ReportsRefreshed();
}

/// Event when a filter is applied to the reports
class ReportsFilterChanged extends ReportsEvent {
  final ReportFilter filter;

  const ReportsFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Event when a search query is entered
class ReportsSearchQueryChanged extends ReportsEvent {
  final String query;

  const ReportsSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event when a report's favorite status is toggled
class ReportFavoriteToggled extends ReportsEvent {
  final String reportId;
  final bool isFavorite;

  const ReportFavoriteToggled({
    required this.reportId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [reportId, isFavorite];
}

/// Event to check and update late reports
class ReportsCheckLateStatus extends ReportsEvent {
  const ReportsCheckLateStatus();

  @override
  List<Object> get props => [];
}

/// Event when a report is marked as completed
class ReportCompleted extends ReportsEvent {
  final String reportId;
  final String completionNote;
  final List<String> completionPhotos;

  const ReportCompleted({
    required this.reportId,
    required this.completionNote,
    required this.completionPhotos,
  });

  @override
  List<Object> get props => [reportId, completionNote, completionPhotos];
}
