import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_event.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_state.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';

/// Bloc for managing the supervisor profile state
class SupervisorBloc extends Bloc<SupervisorEvent, SupervisorState> {
  final ReportRepository _reportRepository;

  /// Creates a new SupervisorBloc
  SupervisorBloc({
    required ReportRepository reportRepository,
  })  : _reportRepository = reportRepository,
        super(const SupervisorState()) {
    on<SupervisorStarted>(_onSupervisorStarted);
    on<SupervisorRefreshed>(_onSupervisorRefreshed);
    on<SupervisorProfileUpdated>(_onSupervisorProfileUpdated);
  }

  /// Handles the SupervisorStarted event
  Future<void> _onSupervisorStarted(
    SupervisorStarted event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(state.copyWith(status: SupervisorStatus.loading));
    try {
      final profile = await _reportRepository.getCurrentUserProfile();
      emit(state.copyWith(
        status: SupervisorStatus.success,
        profile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SupervisorStatus.failure,
        errorMessage: 'Failed to load supervisor profile: $e',
      ));
    }
  }

  /// Handles the SupervisorRefreshed event
  Future<void> _onSupervisorRefreshed(
    SupervisorRefreshed event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(state.copyWith(status: SupervisorStatus.loading));
    try {
      final profile = await _reportRepository.getCurrentUserProfile();
      emit(state.copyWith(
        status: SupervisorStatus.success,
        profile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SupervisorStatus.failure,
        errorMessage: 'Failed to refresh supervisor profile: $e',
      ));
    }
  }

  /// Handles the SupervisorProfileUpdated event
  Future<void> _onSupervisorProfileUpdated(
    SupervisorProfileUpdated event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(state.copyWith(status: SupervisorStatus.loading));
    try {
      // Update the profile in the database
      final updatedProfile = await _reportRepository.updateUserProfile(event.profile);
      
      // Emit the updated profile state
      emit(state.copyWith(
        status: SupervisorStatus.success,
        profile: updatedProfile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SupervisorStatus.failure,
        errorMessage: 'Failed to update supervisor profile: $e',
      ));
    }
  }
}
