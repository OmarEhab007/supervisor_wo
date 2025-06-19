import 'package:equatable/equatable.dart';

/// Base class for all maintenance events
abstract class MaintenanceEvent extends Equatable {
  const MaintenanceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load maintenance reports when the screen is first opened
class MaintenanceStarted extends MaintenanceEvent {
  const MaintenanceStarted();
}

/// Event to refresh maintenance reports
class MaintenanceRefreshed extends MaintenanceEvent {
  const MaintenanceRefreshed();
}

/// Event to complete a maintenance report
class MaintenanceReportCompleted extends MaintenanceEvent {
  final String reportId;
  final String completionNote;
  final List<String> completionPhotos;

  const MaintenanceReportCompleted({
    required this.reportId,
    required this.completionNote,
    required this.completionPhotos,
  });

  @override
  List<Object> get props => [reportId, completionNote, completionPhotos];
}

/// Event when a filter is changed
class MaintenanceFilterChanged extends MaintenanceEvent {
  final String? filter;

  const MaintenanceFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Event when search query is changed
class MaintenanceSearchQueryChanged extends MaintenanceEvent {
  final String query;

  const MaintenanceSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event when a maintenance report is updated
class MaintenanceReportUpdated extends MaintenanceEvent {
  final String reportId;
  final String status;
  final String? completionNote;
  final List<String>? completionPhotos;

  const MaintenanceReportUpdated({
    required this.reportId,
    required this.status,
    this.completionNote,
    this.completionPhotos,
  });

  @override
  List<Object?> get props =>
      [reportId, status, completionNote, completionPhotos];
}

/// Event when a new maintenance report is created
class MaintenanceReportCreated extends MaintenanceEvent {
  final String schoolId;
  final String description;
  final List<String> images;

  const MaintenanceReportCreated({
    required this.schoolId,
    required this.description,
    required this.images,
  });

  @override
  List<Object?> get props => [schoolId, description, images];
}
