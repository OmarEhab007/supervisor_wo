import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/damage_count_model.dart';

/// Base class for damage count events
abstract class DamageCountEvent extends Equatable {
  const DamageCountEvent();

  @override
  List<Object> get props => [];
}

/// Event to start loading schools for damage counting
class DamageCountSchoolsStarted extends DamageCountEvent {
  const DamageCountSchoolsStarted();
}

/// Event to refresh the schools list
class DamageCountSchoolsRefreshed extends DamageCountEvent {
  const DamageCountSchoolsRefreshed();
}

/// Event to start damage count form for a school
class DamageCountFormStarted extends DamageCountEvent {
  final String schoolId;

  const DamageCountFormStarted(this.schoolId);

  @override
  List<Object> get props => [schoolId];
}

/// Event to save damage count
class DamageCountSaved extends DamageCountEvent {
  final DamageCountModel damageCount;

  const DamageCountSaved(this.damageCount);

  @override
  List<Object> get props => [damageCount];
}

/// Event to update damage count
class DamageCountUpdated extends DamageCountEvent {
  final DamageCountModel damageCount;

  const DamageCountUpdated(this.damageCount);

  @override
  List<Object> get props => [damageCount];
}

/// Event to submit damage count with photos
class DamageCountSubmittedWithPhotos extends DamageCountEvent {
  final DamageCountModel damageCount;
  final Map<String, List<String>> sectionPhotos;

  const DamageCountSubmittedWithPhotos(
    this.damageCount,
    this.sectionPhotos,
  );

  @override
  List<Object> get props => [damageCount, sectionPhotos];
}
