import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/damage_count_model.dart';
import 'package:supervisor_wo/models/school_model.dart';

/// Status enum for damage count operations
enum DamageCountStatus {
  initial,
  loading,
  success,
  failure,
  saving,
}

/// State class for damage count operations
class DamageCountState extends Equatable {
  final DamageCountStatus status;
  final List<School> schools;
  final DamageCountModel? currentDamageCount;
  final String? errorMessage;

  const DamageCountState({
    this.status = DamageCountStatus.initial,
    this.schools = const [],
    this.currentDamageCount,
    this.errorMessage,
  });

  DamageCountState copyWith({
    DamageCountStatus? status,
    List<School>? schools,
    DamageCountModel? currentDamageCount,
    String? errorMessage,
  }) {
    return DamageCountState(
      status: status ?? this.status,
      schools: schools ?? this.schools,
      currentDamageCount: currentDamageCount ?? this.currentDamageCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        schools,
        currentDamageCount,
        errorMessage,
      ];
}
