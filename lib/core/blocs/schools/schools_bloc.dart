import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/schools/schools_event.dart';
import 'package:supervisor_wo/core/blocs/schools/schools_state.dart';
import 'package:supervisor_wo/core/repositories/school_repository.dart';

/// Bloc for managing the schools state
class SchoolsBloc extends Bloc<SchoolsEvent, SchoolsState> {
  final SchoolRepository _schoolRepository;

  /// Creates a new SchoolsBloc
  SchoolsBloc({
    required SchoolRepository schoolRepository,
  })  : _schoolRepository = schoolRepository,
        super(const SchoolsState()) {
    on<SchoolsStarted>(_onSchoolsStarted);
    on<SchoolsRefreshed>(_onSchoolsRefreshed);
    on<SchoolSelected>(_onSchoolSelected);
    on<SchoolsSearchQueryChanged>(_onSchoolsSearchQueryChanged);
    on<SchoolsEmergencyFilterToggled>(_onSchoolsEmergencyFilterToggled);
  }

  /// Handles the SchoolsStarted event
  Future<void> _onSchoolsStarted(
    SchoolsStarted event,
    Emitter<SchoolsState> emit,
  ) async {
    emit(state.copyWith(status: SchoolsStatus.loading));
    try {
      final schools = await _schoolRepository.getSchools();
      emit(state.copyWith(
        status: SchoolsStatus.success,
        schools: schools,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SchoolsStatus.failure,
        errorMessage: 'Failed to load schools: $e',
      ));
    }
  }

  /// Handles the SchoolsRefreshed event
  Future<void> _onSchoolsRefreshed(
    SchoolsRefreshed event,
    Emitter<SchoolsState> emit,
  ) async {
    emit(state.copyWith(status: SchoolsStatus.loading));
    try {
      final schools = await _schoolRepository.getSchools();
      emit(state.copyWith(
        status: SchoolsStatus.success,
        schools: schools,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SchoolsStatus.failure,
        errorMessage: 'Failed to refresh schools: $e',
      ));
    }
  }

  /// Handles the SchoolSelected event
  void _onSchoolSelected(
    SchoolSelected event,
    Emitter<SchoolsState> emit,
  ) {
    emit(state.copyWith(selectedSchoolId: event.schoolId));
  }

  /// Handles the SchoolsSearchQueryChanged event
  void _onSchoolsSearchQueryChanged(
    SchoolsSearchQueryChanged event,
    Emitter<SchoolsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  /// Handles the SchoolsEmergencyFilterToggled event
  void _onSchoolsEmergencyFilterToggled(
    SchoolsEmergencyFilterToggled event,
    Emitter<SchoolsState> emit,
  ) {
    emit(state.copyWith(showOnlyEmergency: event.showOnlyEmergency));
  }
}
