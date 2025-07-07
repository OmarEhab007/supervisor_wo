import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/damage_count/damage_count_event.dart';
import 'package:supervisor_wo/core/blocs/damage_count/damage_count_state.dart';
import 'package:supervisor_wo/core/repositories/damage_count_repository.dart';

/// Bloc for handling damage count operations
class DamageCountBloc extends Bloc<DamageCountEvent, DamageCountState> {
  final DamageCountRepository repository;

  DamageCountBloc({
    required this.repository,
  }) : super(const DamageCountState()) {
    on<DamageCountSchoolsStarted>(_onSchoolsStarted);
    on<DamageCountSchoolsRefreshed>(_onSchoolsRefreshed);
    on<DamageCountFormStarted>(_onFormStarted);
    on<DamageCountSaved>(_onCountSaved);
    on<DamageCountUpdated>(_onCountUpdated);
    on<DamageCountSubmittedWithPhotos>(_onDamageCountSubmittedWithPhotos);
  }

  /// Handle DamageCountSchoolsStarted event
  Future<void> _onSchoolsStarted(
    DamageCountSchoolsStarted event,
    Emitter<DamageCountState> emit,
  ) async {
    emit(state.copyWith(status: DamageCountStatus.loading));

    try {
      print('🔍 DEBUG: Starting to load damage count schools...');
      final schools = await repository.getDamageSchools();

      print('🔍 DEBUG: Loaded ${schools.length} schools for damage count');

      emit(state.copyWith(
        status: DamageCountStatus.success,
        schools: schools,
      ));
    } catch (e) {
      print('🔍 DEBUG: Error loading schools in damage count bloc: $e');
      emit(state.copyWith(
        status: DamageCountStatus.failure,
        errorMessage: 'Failed to load schools: $e',
      ));
    }
  }

  /// Handle DamageCountSchoolsRefreshed event
  Future<void> _onSchoolsRefreshed(
    DamageCountSchoolsRefreshed event,
    Emitter<DamageCountState> emit,
  ) async {
    try {
      final schools = await repository.getDamageSchools();

      emit(state.copyWith(
        status: DamageCountStatus.success,
        schools: schools,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DamageCountStatus.failure,
        errorMessage: 'Failed to refresh schools: $e',
      ));
    }
  }

  /// Handle DamageCountFormStarted event
  Future<void> _onFormStarted(
    DamageCountFormStarted event,
    Emitter<DamageCountState> emit,
  ) async {
    emit(state.copyWith(status: DamageCountStatus.loading));

    try {
      // Try to fetch existing damage count for this school
      final existingCount =
          await repository.getDamageCountBySchool(event.schoolId);

      emit(state.copyWith(
        status: DamageCountStatus.success,
        currentDamageCount: existingCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DamageCountStatus.failure,
        errorMessage: 'Failed to load damage count: $e',
      ));
    }
  }

  /// Handle DamageCountSaved event
  Future<void> _onCountSaved(
    DamageCountSaved event,
    Emitter<DamageCountState> emit,
  ) async {
    emit(state.copyWith(status: DamageCountStatus.saving));

    try {
      final success = await repository.saveDamageCount(event.damageCount);

      if (success) {
        emit(state.copyWith(
          status: DamageCountStatus.success,
          currentDamageCount: event.damageCount,
        ));
      } else {
        emit(state.copyWith(
          status: DamageCountStatus.failure,
          errorMessage: 'Failed to save damage count',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DamageCountStatus.failure,
        errorMessage: 'Failed to save damage count: $e',
      ));
    }
  }

  /// Handle DamageCountUpdated event
  Future<void> _onCountUpdated(
    DamageCountUpdated event,
    Emitter<DamageCountState> emit,
  ) async {
    emit(state.copyWith(status: DamageCountStatus.saving));

    try {
      final success = await repository.updateDamageCount(event.damageCount);

      if (success) {
        emit(state.copyWith(
          status: DamageCountStatus.success,
          currentDamageCount: event.damageCount,
        ));
      } else {
        emit(state.copyWith(
          status: DamageCountStatus.failure,
          errorMessage: 'Failed to update damage count',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DamageCountStatus.failure,
        errorMessage: 'Failed to update damage count: $e',
      ));
    }
  }

  /// Handle DamageCountSubmittedWithPhotos event
  Future<void> _onDamageCountSubmittedWithPhotos(
    DamageCountSubmittedWithPhotos event,
    Emitter<DamageCountState> emit,
  ) async {
    emit(state.copyWith(status: DamageCountStatus.saving));

    try {
      final success = await repository.saveDamageCountWithPhotos(
        event.damageCount,
        event.sectionPhotos,
      );

      if (success) {
        emit(state.copyWith(
          status: DamageCountStatus.success,
          currentDamageCount: event.damageCount,
        ));
      } else {
        emit(state.copyWith(
          status: DamageCountStatus.failure,
          errorMessage: 'فشل في حفظ البيانات',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DamageCountStatus.failure,
        errorMessage: 'Failed to save damage count with photos: $e',
      ));
    }
  }
}
