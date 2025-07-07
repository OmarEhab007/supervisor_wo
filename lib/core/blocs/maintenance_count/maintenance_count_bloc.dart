import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/maintenance_count/maintenance_count_event.dart';
import 'package:supervisor_wo/core/blocs/maintenance_count/maintenance_count_state.dart';
import 'package:supervisor_wo/core/repositories/maintenance_count_repository.dart';

/// Bloc for handling maintenance count operations
class MaintenanceCountBloc
    extends Bloc<MaintenanceCountEvent, MaintenanceCountState> {
  final MaintenanceCountRepository repository;

  MaintenanceCountBloc({
    required this.repository,
  }) : super(const MaintenanceCountState()) {
    on<MaintenanceCountSchoolsStarted>(_onSchoolsStarted);
    on<MaintenanceCountSchoolsRefreshed>(_onSchoolsRefreshed);
    on<MaintenanceCountFormStarted>(_onFormStarted);
    on<MaintenanceCountSaved>(_onCountSaved);
    on<MaintenanceCountUpdated>(_onCountUpdated);
    on<MaintenanceCountSubmittedWithPhotos>(
        _onMaintenanceCountSubmittedWithPhotos);
  }

  /// Handle MaintenanceCountSchoolsStarted event
  Future<void> _onSchoolsStarted(
    MaintenanceCountSchoolsStarted event,
    Emitter<MaintenanceCountState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceCountStatus.loading));

    try {
      // Add debug information
      print('🔍 DEBUG: Starting to load schools...');
      await repository.debugDatabaseConnection();

      // Fetch both types of schools
      final schoolsWithReports =
          await repository.getSchoolsWithMaintenanceReports();
      final manuallyAssignedSchools =
          await repository.getManuallyAssignedSchools();

      // Combine for backward compatibility
      final allSchools = [...schoolsWithReports, ...manuallyAssignedSchools];

      print(
          '🔍 DEBUG: Loaded ${schoolsWithReports.length} schools with reports');
      print(
          '🔍 DEBUG: Loaded ${manuallyAssignedSchools.length} manually assigned schools');
      print('🔍 DEBUG: Total ${allSchools.length} schools in bloc');

      emit(state.copyWith(
        status: MaintenanceCountStatus.success,
        schools: allSchools,
        schoolsWithReports: schoolsWithReports,
        manuallyAssignedSchools: manuallyAssignedSchools,
      ));
    } catch (e) {
      print('🔍 DEBUG: Error loading schools in bloc: $e');
      emit(state.copyWith(
        status: MaintenanceCountStatus.failure,
        errorMessage: 'Failed to load schools: $e',
      ));
    }
  }

  /// Handle MaintenanceCountSchoolsRefreshed event
  Future<void> _onSchoolsRefreshed(
    MaintenanceCountSchoolsRefreshed event,
    Emitter<MaintenanceCountState> emit,
  ) async {
    try {
      // Fetch both types of schools
      final schoolsWithReports =
          await repository.getSchoolsWithMaintenanceReports();
      final manuallyAssignedSchools =
          await repository.getManuallyAssignedSchools();

      // Combine for backward compatibility
      final allSchools = [...schoolsWithReports, ...manuallyAssignedSchools];

      emit(state.copyWith(
        status: MaintenanceCountStatus.success,
        schools: allSchools,
        schoolsWithReports: schoolsWithReports,
        manuallyAssignedSchools: manuallyAssignedSchools,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceCountStatus.failure,
        errorMessage: 'Failed to refresh schools: $e',
      ));
    }
  }

  /// Handle MaintenanceCountFormStarted event
  Future<void> _onFormStarted(
    MaintenanceCountFormStarted event,
    Emitter<MaintenanceCountState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceCountStatus.loading));

    try {
      // Try to fetch existing maintenance count for this school
      final existingCount =
          await repository.getMaintenanceCountBySchool(event.schoolId);

      emit(state.copyWith(
        status: MaintenanceCountStatus.success,
        currentMaintenanceCount: existingCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceCountStatus.failure,
        errorMessage: 'Failed to load maintenance count: $e',
      ));
    }
  }

  /// Handle MaintenanceCountSaved event
  Future<void> _onCountSaved(
    MaintenanceCountSaved event,
    Emitter<MaintenanceCountState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceCountStatus.saving));

    try {
      final success =
          await repository.saveMaintenanceCount(event.maintenanceCount);

      if (success) {
        emit(state.copyWith(
          status: MaintenanceCountStatus.success,
          currentMaintenanceCount: event.maintenanceCount,
        ));
      } else {
        emit(state.copyWith(
          status: MaintenanceCountStatus.failure,
          errorMessage: 'Failed to save maintenance count',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceCountStatus.failure,
        errorMessage: 'Failed to save maintenance count: $e',
      ));
    }
  }

  /// Handle MaintenanceCountUpdated event
  Future<void> _onCountUpdated(
    MaintenanceCountUpdated event,
    Emitter<MaintenanceCountState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceCountStatus.saving));

    try {
      final success =
          await repository.updateMaintenanceCount(event.maintenanceCount);

      if (success) {
        emit(state.copyWith(
          status: MaintenanceCountStatus.success,
          currentMaintenanceCount: event.maintenanceCount,
        ));
      } else {
        emit(state.copyWith(
          status: MaintenanceCountStatus.failure,
          errorMessage: 'Failed to update maintenance count',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceCountStatus.failure,
        errorMessage: 'Failed to update maintenance count: $e',
      ));
    }
  }

  /// Handle MaintenanceCountSubmittedWithPhotos event
  Future<void> _onMaintenanceCountSubmittedWithPhotos(
    MaintenanceCountSubmittedWithPhotos event,
    Emitter<MaintenanceCountState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceCountStatus.saving));

    try {
      final success = await repository.saveMaintenanceCountWithPhotos(
        event.maintenanceCount,
        event.sectionPhotos,
      );

      if (success) {
        emit(state.copyWith(
          status: MaintenanceCountStatus.success,
          currentMaintenanceCount: event.maintenanceCount,
        ));
      } else {
        emit(state.copyWith(
          status: MaintenanceCountStatus.failure,
          errorMessage: 'فشل في حفظ البيانات',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceCountStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
