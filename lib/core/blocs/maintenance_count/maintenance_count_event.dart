import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/maintenance_count_model.dart';

/// Base class for maintenance count events
abstract class MaintenanceCountEvent extends Equatable {
  const MaintenanceCountEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start loading schools for maintenance counting
class MaintenanceCountSchoolsStarted extends MaintenanceCountEvent {
  const MaintenanceCountSchoolsStarted();
}

/// Event to refresh schools list
class MaintenanceCountSchoolsRefreshed extends MaintenanceCountEvent {
  const MaintenanceCountSchoolsRefreshed();
}

/// Event to start maintenance count form for a specific school
class MaintenanceCountFormStarted extends MaintenanceCountEvent {
  final String schoolId;

  const MaintenanceCountFormStarted({required this.schoolId});

  @override
  List<Object?> get props => [schoolId];
}

/// Event to save maintenance count data
class MaintenanceCountSaved extends MaintenanceCountEvent {
  final MaintenanceCountModel maintenanceCount;

  const MaintenanceCountSaved({required this.maintenanceCount});

  @override
  List<Object?> get props => [maintenanceCount];
}

/// Event to update existing maintenance count data
class MaintenanceCountUpdated extends MaintenanceCountEvent {
  final MaintenanceCountModel maintenanceCount;

  const MaintenanceCountUpdated({required this.maintenanceCount});

  @override
  List<Object?> get props => [maintenanceCount];
}

/// Event to save maintenance count data with photos
class MaintenanceCountSubmittedWithPhotos extends MaintenanceCountEvent {
  final MaintenanceCountModel maintenanceCount;
  final Map<String, List<String>> sectionPhotos;

  const MaintenanceCountSubmittedWithPhotos({
    required this.maintenanceCount,
    required this.sectionPhotos,
  });

  @override
  List<Object> get props => [maintenanceCount, sectionPhotos];
}
