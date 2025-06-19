import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/completion_rate/completion_rate_event.dart';
import 'package:supervisor_wo/core/blocs/completion_rate/completion_rate_state.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';

/// BLoC for the completion rate screen
class CompletionRateBloc
    extends Bloc<CompletionRateEvent, CompletionRateState> {
  final ReportRepository _reportRepository;

  /// Creates a new CompletionRateBloc
  CompletionRateBloc({
    required ReportRepository reportRepository,
  })  : _reportRepository = reportRepository,
        super(const CompletionRateState()) {
    on<CompletionRateStarted>(_onCompletionRateStarted);
    on<CompletionRateRefreshed>(_onCompletionRateRefreshed);
  }

  /// Handles the CompletionRateStarted event
  Future<void> _onCompletionRateStarted(
    CompletionRateStarted event,
    Emitter<CompletionRateState> emit,
  ) async {
    emit(state.copyWith(status: CompletionRateStatus.loading));
    try {
      await _loadCompletionRateData(emit);
    } catch (e) {
      emit(state.copyWith(
        status: CompletionRateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handles the CompletionRateRefreshed event
  Future<void> _onCompletionRateRefreshed(
    CompletionRateRefreshed event,
    Emitter<CompletionRateState> emit,
  ) async {
    emit(state.copyWith(status: CompletionRateStatus.loading));
    try {
      await _loadCompletionRateData(emit);
    } catch (e) {
      emit(state.copyWith(
        status: CompletionRateStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Loads the completion rate data
  Future<void> _loadCompletionRateData(
      Emitter<CompletionRateState> emit) async {
    // Fetch all reports
    final reports = await _reportRepository.getReports();

    // Calculate statistics
    final totalReports = reports.length;
    final completedReports =
        reports.where((r) => r.status == 'completed').length;
    final lateCompletedReports =
        reports.where((r) => r.status == 'late_completed').length;

    // Late reports: status is 'late'
    final lateReports = reports.where((r) => r.status == 'late').length;

    // Pending reports: status is pending or in_progress, and not overdue
    // Use normalized date comparison like the home screen
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final pendingReports = reports.where((r) {
      if (r.status != 'pending' && r.status != 'in_progress') {
        return false;
      }
      
      // Normalize the scheduled date to compare just the date part
      final scheduledDate = DateTime(
        r.scheduledDate.year,
        r.scheduledDate.month,
        r.scheduledDate.day,
      );
      
      // Include reports scheduled for today or future dates
      return scheduledDate.isAtSameMomentAs(today) || scheduledDate.isAfter(today);
    }).length;

    // Calculate average response time (in hours)
    double averageResponseTime = 0;
    final completedReportsWithResponseTime = reports.where((r) =>
        (r.status == 'completed' || r.status == 'late_completed') &&
        r.closedAt != null);

    if (completedReportsWithResponseTime.isNotEmpty) {
      final totalResponseTime = completedReportsWithResponseTime.fold<double>(
          0,
          (sum, report) =>
              sum + report.closedAt!.difference(report.createdAt).inHours);
      averageResponseTime =
          totalResponseTime / completedReportsWithResponseTime.length;
    }

    emit(state.copyWith(
      status: CompletionRateStatus.success,
      totalReports: totalReports,
      completedReports: completedReports,
      lateCompletedReports: lateCompletedReports,
      pendingReports: pendingReports,
      lateReports: lateReports,
      averageResponseTime: averageResponseTime,
    ));
  }
}
