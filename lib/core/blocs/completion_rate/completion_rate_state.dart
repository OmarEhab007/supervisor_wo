import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Status of the completion rate bloc
enum CompletionRateStatus {
  /// Initial state
  initial,

  /// Loading state
  loading,

  /// Success state
  success,

  /// Failure state
  failure,
}

/// State for the completion rate bloc
@immutable
class CompletionRateState extends Equatable {
  /// Status of the completion rate bloc
  final CompletionRateStatus status;

  /// Error message if status is failure
  final String? errorMessage;

  /// Total number of reports
  final int totalReports;

  /// Number of completed reports
  final int completedReports;

  /// Number of late completed reports
  final int lateCompletedReports;

  /// Number of pending reports (not overdue)
  final int pendingReports;

  /// Number of late (pending and overdue) reports
  final int lateReports;

  /// Average response time in hours
  final double averageResponseTime;

  /// Creates a new CompletionRateState
  const CompletionRateState({
    this.status = CompletionRateStatus.initial,
    this.errorMessage,
    this.totalReports = 0,
    this.completedReports = 0,
    this.lateCompletedReports = 0,
    this.pendingReports = 0,
    this.lateReports = 0,
    this.averageResponseTime = 0,
  });

  /// Creates a copy of this state with the given fields replaced
  CompletionRateState copyWith({
    CompletionRateStatus? status,
    String? errorMessage,
    int? totalReports,
    int? completedReports,
    int? lateCompletedReports,
    int? pendingReports,
    int? lateReports,
    double? averageResponseTime,
  }) {
    return CompletionRateState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      totalReports: totalReports ?? this.totalReports,
      completedReports: completedReports ?? this.completedReports,
      lateCompletedReports: lateCompletedReports ?? this.lateCompletedReports,
      pendingReports: pendingReports ?? this.pendingReports,
      lateReports: lateReports ?? this.lateReports,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
    );
  }

  /// Gets the overall completion rate
  double get overallCompletionRate {
    if (totalReports == 0) return 0;
    return (completedReports / totalReports) * 100;
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        totalReports,
        completedReports,
        lateCompletedReports,
        pendingReports,
        lateReports,
        averageResponseTime,
      ];
}
