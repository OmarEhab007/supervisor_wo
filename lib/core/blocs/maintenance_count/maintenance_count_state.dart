import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/maintenance_count_model.dart';
import 'package:supervisor_wo/models/school_model.dart';

/// Status enum for maintenance count operations
enum MaintenanceCountStatus {
  initial,
  loading,
  success,
  saving,
  failure,
}

/// State class for maintenance count operations
class MaintenanceCountState extends Equatable {
  final MaintenanceCountStatus status;
  final List<School> schools; // Keep for backward compatibility
  final List<School>
      schoolsWithReports; // Schools that have maintenance reports
  final List<School>
      manuallyAssignedSchools; // Schools manually assigned via floating button
  final MaintenanceCountModel? currentMaintenanceCount;
  final String? errorMessage;

  const MaintenanceCountState({
    this.status = MaintenanceCountStatus.initial,
    this.schools = const [],
    this.schoolsWithReports = const [],
    this.manuallyAssignedSchools = const [],
    this.currentMaintenanceCount,
    this.errorMessage,
  });

  /// Create a copy of the state with updated values
  MaintenanceCountState copyWith({
    MaintenanceCountStatus? status,
    List<School>? schools,
    List<School>? schoolsWithReports,
    List<School>? manuallyAssignedSchools,
    MaintenanceCountModel? currentMaintenanceCount,
    String? errorMessage,
  }) {
    return MaintenanceCountState(
      status: status ?? this.status,
      schools: schools ?? this.schools,
      schoolsWithReports: schoolsWithReports ?? this.schoolsWithReports,
      manuallyAssignedSchools:
          manuallyAssignedSchools ?? this.manuallyAssignedSchools,
      currentMaintenanceCount:
          currentMaintenanceCount ?? this.currentMaintenanceCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        schools,
        schoolsWithReports,
        manuallyAssignedSchools,
        currentMaintenanceCount,
        errorMessage,
      ];
}
