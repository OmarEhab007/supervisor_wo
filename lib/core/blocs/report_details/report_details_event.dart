import 'package:equatable/equatable.dart';

/// Base class for all ReportDetailsBloc events
abstract class ReportDetailsEvent extends Equatable {
  const ReportDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the report details
class ReportDetailsLoaded extends ReportDetailsEvent {
  final String reportId;

  const ReportDetailsLoaded(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

/// Event when the report is approved
class ReportApproved extends ReportDetailsEvent {
  final String reportId;

  const ReportApproved(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

/// Event when feedback is sent for the report
class ReportFeedbackSent extends ReportDetailsEvent {
  final String reportId;
  final String feedback;

  const ReportFeedbackSent({
    required this.reportId,
    required this.feedback,
  });

  @override
  List<Object?> get props => [reportId, feedback];
}

/// Event when the report is shared
class ReportShared extends ReportDetailsEvent {
  final String reportId;

  const ReportShared(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

/// Event when the report status is updated
class ReportStatusUpdated extends ReportDetailsEvent {
  final String reportId;
  final String status;

  const ReportStatusUpdated({
    required this.reportId,
    required this.status,
  });

  @override
  List<Object?> get props => [reportId, status];
}
