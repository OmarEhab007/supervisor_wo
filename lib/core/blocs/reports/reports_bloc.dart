import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';
import 'package:supervisor_wo/core/extensions/report_extensions.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';
import 'package:supervisor_wo/models/report_model.dart';

/// Bloc for managing the reports screen state
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportRepository _reportRepository;

  ReportsBloc({required ReportRepository reportRepository})
      : _reportRepository = reportRepository,
        super(const ReportsState()) {
    on<ReportsStarted>(_onReportsStarted);
    on<ReportsRefreshed>(_onReportsRefreshed);
    on<ReportsFilterChanged>(_onReportsFilterChanged);
    on<ReportsSearchQueryChanged>(_onReportsSearchQueryChanged);
    on<ReportFavoriteToggled>(_onReportFavoriteToggled);
    on<ReportsCheckLateStatus>(_onReportsCheckLateStatus);
    on<ReportCompleted>(_onReportCompleted);
    on<ReportsStatusCleared>((event, emit) {
      emit(state.copyWith(status: ReportsStatus.initial, errorMessage: null));
    });
  }

  /// Handle the ReportsStarted event
  Future<void> _onReportsStarted(
    ReportsStarted event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(status: ReportsStatus.loading));

    try {
      final reports = await _reportRepository.getReports();

      // Check for late reports
      final updatedReports = await _checkForLateReports(reports);

      // Compute filtered results
      final filteredReports = _computeFilteredReports(
          updatedReports, state.activeFilter, state.searchQuery);
      final upcomingReports = _computeUpcomingReports(updatedReports);

      emit(state.copyWith(
        status: ReportsStatus.success,
        reports: updatedReports,
        cachedFilteredReports: filteredReports,
        cachedUpcomingReports: upcomingReports,
      ));

      // Schedule a check for late reports
      add(const ReportsCheckLateStatus());
    } catch (e) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handle the ReportsRefreshed event
  Future<void> _onReportsRefreshed(
    ReportsRefreshed event,
    Emitter<ReportsState> emit,
  ) async {
    // Keep the current data while refreshing
    emit(state.copyWith(status: ReportsStatus.loading));

    try {
      final reports = await _reportRepository.getReports();

      // Check for late reports
      final updatedReports = await _checkForLateReports(reports);

      // Compute filtered results
      final filteredReports = _computeFilteredReports(
          updatedReports, state.activeFilter, state.searchQuery);
      final upcomingReports = _computeUpcomingReports(updatedReports);

      emit(state.copyWith(
        status: ReportsStatus.success,
        reports: updatedReports,
        cachedFilteredReports: filteredReports,
        cachedUpcomingReports: upcomingReports,
      ));

      // Schedule a check for late reports
      add(const ReportsCheckLateStatus());
    } catch (e) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handle the ReportsFilterChanged event
  void _onReportsFilterChanged(
    ReportsFilterChanged event,
    Emitter<ReportsState> emit,
  ) {
    // Recompute filtered reports with new filter
    final filteredReports =
        _computeFilteredReports(state.reports, event.filter, state.searchQuery);

    emit(state.copyWith(
      activeFilter: event.filter,
      cachedFilteredReports: filteredReports,
    ));
  }

  /// Handle the ReportsSearchQueryChanged event
  void _onReportsSearchQueryChanged(
    ReportsSearchQueryChanged event,
    Emitter<ReportsState> emit,
  ) {
    // Recompute filtered reports with new search query
    final filteredReports =
        _computeFilteredReports(state.reports, state.activeFilter, event.query);

    emit(state.copyWith(
      searchQuery: event.query,
      cachedFilteredReports: filteredReports,
    ));
  }

  /// Handle the ReportFavoriteToggled event
  void _onReportFavoriteToggled(
    ReportFavoriteToggled event,
    Emitter<ReportsState> emit,
  ) {
    // In a real app, this would update the favorite status in the database
    // For now, we'll just show how we would handle this event
    emit(state.copyWith(status: ReportsStatus.success));
  }

  /// Handle the ReportCompleted event
  Future<void> _onReportCompleted(
    ReportCompleted event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(status: ReportsStatus.loading));

    try {
      // Call the repository to complete the report
      final success = await _reportRepository.completeReport(
        reportId: event.reportId,
        completionNote: event.completionNote,
        completionPhotos: event.completionPhotos,
      );

      if (success) {
        // Refresh the reports list to show the updated status
        final reports = await _reportRepository.getReports();

        // Recompute all cached data
        final filteredReports = _computeFilteredReports(
            reports, state.activeFilter, state.searchQuery);
        final upcomingReports = _computeUpcomingReports(reports);

        emit(state.copyWith(
          status: ReportsStatus.success,
          reports: reports,
          cachedFilteredReports: filteredReports,
          cachedUpcomingReports: upcomingReports,
        ));
      } else {
        emit(state.copyWith(
          status: ReportsStatus.failure,
          errorMessage: 'Failed to complete the report',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: 'Error completing report: ${e.toString()}',
      ));
    }
  }

  /// Handle the ReportsCheckLateStatus event
  Future<void> _onReportsCheckLateStatus(
    ReportsCheckLateStatus event,
    Emitter<ReportsState> emit,
  ) async {
    if (state.reports.isEmpty) return;

    final updatedReports = await _checkForLateReports(state.reports);

    // Only emit if there are changes
    if (updatedReports != state.reports) {
      // Recompute all cached data
      final filteredReports = _computeFilteredReports(
          updatedReports, state.activeFilter, state.searchQuery);
      final upcomingReports = _computeUpcomingReports(updatedReports);

      emit(state.copyWith(
        reports: updatedReports,
        cachedFilteredReports: filteredReports,
        cachedUpcomingReports: upcomingReports,
      ));
    }
  }

  // === FILTERING UTILITIES ===

  /// Centralized filtering logic for reports based on filter and search query
  List<Report> _computeFilteredReports(
    List<Report> reports,
    ReportFilter filter,
    String searchQuery,
  ) {
    // First apply search filter if any
    final searchFiltered = _applySearchFilter(reports, searchQuery);

    // Then apply status filter
    return _applyStatusFilter(searchFiltered, filter);
  }

  /// Apply search filtering to reports
  List<Report> _applySearchFilter(List<Report> reports, String searchQuery) {
    if (searchQuery.isEmpty) return reports;

    final query = searchQuery.toLowerCase();
    return reports
        .where((report) =>
            report.description.toLowerCase().contains(query) ||
            report.schoolName.toLowerCase().contains(query))
        .toList();
  }

  /// Apply status filtering to reports
  List<Report> _applyStatusFilter(List<Report> reports, ReportFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case ReportFilter.all:
        return reports;
      case ReportFilter.pending:
        return reports.where((report) => report.status == 'pending').toList();
      case ReportFilter.completed:
        return reports.where((report) => report.status == 'completed').toList();
      case ReportFilter.lateCompleted:
        return reports.where((report) => report.status == 'late_completed').toList();
      case ReportFilter.issues:
        return reports
            .where((report) =>
                report.status == 'issues' || report.status == 'late')
            .toList();
      case ReportFilter.recent:
        final sorted = List<Report>.from(reports)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted.take(10).toList();
      case ReportFilter.today:
        return reports.where((report) {
          final scheduledDate = DateTime(
            report.scheduledDate.year,
            report.scheduledDate.month,
            report.scheduledDate.day,
          );
          return scheduledDate.isAtSameMomentAs(today) &&
              report.status != 'completed';
        }).toList();
      case ReportFilter.late:
        return reports.where((report) => report.status == 'late').toList();
    }
  }

  /// Compute upcoming reports for the main reports button
  /// This replaces the duplicated filtering logic in the UI
  List<Report> _computeUpcomingReports(List<Report> reports) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threeDaysLater = today.add(const Duration(days: 3));

    return reports.where((report) {
      // Check if report is pending
      if (report.status != 'pending') return false;

      // Check if scheduled date is today, tomorrow, or after tomorrow (within 3 days)
      final scheduledDate = DateTime(
        report.scheduledDate.year,
        report.scheduledDate.month,
        report.scheduledDate.day,
      );

      return scheduledDate.compareTo(today) >= 0 &&
          scheduledDate.compareTo(threeDaysLater) < 0;
    }).toList();
  }

  /// Check for reports that are past their scheduled date and mark them as late
  /// A report is considered late if the current date is at least one day after the scheduled date
  /// This also updates the status in the database
  Future<List<Report>> _checkForLateReports(List<Report> reports) async {
    // Get current date without time component for cleaner comparison
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    final updatedReports = <Report>[];

    for (final report in reports) {
      // Only check reports with 'pending' status
      if (report.status != 'pending') {
        updatedReports.add(report);
        continue;
      }

      // Get just the date component of the scheduled date
      final scheduledDate = DateTime(
        report.scheduledDate.year,
        report.scheduledDate.month,
        report.scheduledDate.day,
      );

      // Add one day to scheduled date to get the day after
      final dayAfterScheduled = scheduledDate.add(const Duration(days: 1));

      // If current date is on or after the day after scheduled, it's late
      // This means if scheduled for May 30, it becomes late on May 31
      if (currentDate.compareTo(dayAfterScheduled) >= 0) {
        // Create a copy with 'late' status using the extension method
        final lateReport = report.copyWith(status: 'late');
        updatedReports.add(lateReport);

        // Update the status in the database
        await _reportRepository.updateReportStatus(report.id, 'late');

        print(
            'Marked report ${report.id} as late: scheduled for ${scheduledDate.toIso8601String()} and updated in database');
      } else {
        updatedReports.add(report);
      }
    }

    return updatedReports;
  }
}
