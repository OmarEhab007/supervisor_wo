import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/report_model.dart';

/// Status enum for ReportDetailsState
enum ReportDetailsStatus {
  initial,
  loading,
  success,
  failure,
}

/// State for the ReportDetailsBloc
class ReportDetailsState extends Equatable {
  final ReportDetailsStatus status;
  final Report? report;
  final bool isApproving;
  final bool isSendingFeedback;
  final String? errorMessage;

  const ReportDetailsState({
    this.status = ReportDetailsStatus.initial,
    this.report,
    this.isApproving = false,
    this.isSendingFeedback = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        status,
        report,
        isApproving,
        isSendingFeedback,
        errorMessage,
      ];

  /// Create a copy of this ReportDetailsState with the given fields replaced with new values
  ReportDetailsState copyWith({
    ReportDetailsStatus? status,
    Report? report,
    bool? isApproving,
    bool? isSendingFeedback,
    String? errorMessage,
  }) {
    return ReportDetailsState(
      status: status ?? this.status,
      report: report ?? this.report,
      isApproving: isApproving ?? this.isApproving,
      isSendingFeedback: isSendingFeedback ?? this.isSendingFeedback,
      errorMessage: errorMessage,
    );
  }
}
