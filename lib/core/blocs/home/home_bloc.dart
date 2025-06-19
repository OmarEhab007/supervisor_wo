import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/home/home_event.dart';
import 'package:supervisor_wo/core/blocs/home/home_state.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';

/// Bloc for managing the home screen state
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ReportRepository _reportRepository;

  HomeBloc({required ReportRepository reportRepository})
      : _reportRepository = reportRepository,
        super(const HomeState()) {
    on<HomeStarted>(_onHomeStarted);
    on<HomeRefreshed>(_onHomeRefreshed);
    on<ReportFavoriteToggled>(_onReportFavoriteToggled);
  }

  /// Handle the HomeStarted event
  Future<void> _onHomeStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final reports = await _reportRepository.getReports();

      // Take only the 3 most recent reports for the home screen
      final recentReports = reports.take(3).toList();

      // Calculate stats
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get reports for today
      final todayReports = reports.where((r) {
        final reportDate = DateTime(
          r.scheduledDate.year,
          r.scheduledDate.month,
          r.scheduledDate.day,
        );
        return reportDate.isAtSameMomentAs(today) && r.status != 'completed';
      }).length;

      // Get completed reports
      final completedReports =
          reports.where((r) => r.status == 'completed').length;

      // Get late reports
      final lateReports = reports.where((r) => r.status == 'late').length;

      // Calculate completion rate
      final totalReports = reports.length;
      final completionRate = totalReports > 0
          ? ((completedReports / totalReports) * 100).round()
          : 0;

      // Calculate historical data for trends
      final yesterday = today.subtract(const Duration(days: 1));
      final lastWeek = today.subtract(const Duration(days: 7));
      final lastMonth = today.subtract(const Duration(days: 30));

      // Yesterday's reports
      final yesterdayReports = reports.where((r) {
        final reportDate = DateTime(
          r.scheduledDate.year,
          r.scheduledDate.month,
          r.scheduledDate.day,
        );
        return reportDate.isAtSameMomentAs(yesterday) && r.status != 'completed';
      }).length;

      // Last week's completed reports
      final lastWeekCompleted = reports.where((r) {
        return r.status == 'completed' && 
               r.scheduledDate.isBefore(lastWeek) &&
               r.scheduledDate.isAfter(lastWeek.subtract(const Duration(days: 7)));
      }).length;

      // Last month's late reports
      final lastMonthLate = reports.where((r) {
        return r.status == 'late' && 
               r.scheduledDate.isBefore(lastMonth) &&
               r.scheduledDate.isAfter(lastMonth.subtract(const Duration(days: 30)));
      }).length;

      // Last month's completion rate
      final lastMonthReports = reports.where((r) {
        return r.scheduledDate.isBefore(lastMonth) &&
               r.scheduledDate.isAfter(lastMonth.subtract(const Duration(days: 30)));
      }).toList();
      
      final lastMonthCompleted = lastMonthReports.where((r) => r.status == 'completed').length;
      final lastMonthCompletionRate = lastMonthReports.isNotEmpty
          ? ((lastMonthCompleted / lastMonthReports.length) * 100).round()
          : 0;

      final stats = {
        'today': todayReports,
        'completed': completedReports,
        'late': lateReports,
        'completion_rate': completionRate,
        // Historical data for trends
        'yesterday': yesterdayReports,
        'last_week_completed': lastWeekCompleted,
        'last_month_late': lastMonthLate,
        'last_month_completion_rate': lastMonthCompletionRate,
      };

      emit(state.copyWith(
        status: HomeStatus.success,
        recentReports: recentReports,
        stats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handle the HomeRefreshed event
  Future<void> _onHomeRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    // Keep the current data while refreshing
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final reports = await _reportRepository.getReports();

      // Take only the 3 most recent reports for the home screen
      final recentReports = reports.take(3).toList();

      // Calculate stats
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get reports for today
      final todayReports = reports.where((r) {
        final reportDate = DateTime(
          r.scheduledDate.year,
          r.scheduledDate.month,
          r.scheduledDate.day,
        );
        return reportDate.isAtSameMomentAs(today) && r.status != 'completed';
      }).length;

      // Get completed reports
      final completedReports =
          reports.where((r) => r.status == 'completed').length;

      // Get late reports
      final lateReports = reports.where((r) => r.status == 'late').length;

      // Calculate completion rate
      final totalReports = reports.length;
      final completionRate = totalReports > 0
          ? ((completedReports / totalReports) * 100).round()
          : 0;

      // Calculate historical data for trends
      final yesterday = today.subtract(const Duration(days: 1));
      final lastWeek = today.subtract(const Duration(days: 7));
      final lastMonth = today.subtract(const Duration(days: 30));

      // Yesterday's reports
      final yesterdayReports = reports.where((r) {
        final reportDate = DateTime(
          r.scheduledDate.year,
          r.scheduledDate.month,
          r.scheduledDate.day,
        );
        return reportDate.isAtSameMomentAs(yesterday) && r.status != 'completed';
      }).length;

      // Last week's completed reports
      final lastWeekCompleted = reports.where((r) {
        return r.status == 'completed' && 
               r.scheduledDate.isBefore(lastWeek) &&
               r.scheduledDate.isAfter(lastWeek.subtract(const Duration(days: 7)));
      }).length;

      // Last month's late reports
      final lastMonthLate = reports.where((r) {
        return r.status == 'late' && 
               r.scheduledDate.isBefore(lastMonth) &&
               r.scheduledDate.isAfter(lastMonth.subtract(const Duration(days: 30)));
      }).length;

      // Last month's completion rate
      final lastMonthReports = reports.where((r) {
        return r.scheduledDate.isBefore(lastMonth) &&
               r.scheduledDate.isAfter(lastMonth.subtract(const Duration(days: 30)));
      }).toList();
      
      final lastMonthCompleted = lastMonthReports.where((r) => r.status == 'completed').length;
      final lastMonthCompletionRate = lastMonthReports.isNotEmpty
          ? ((lastMonthCompleted / lastMonthReports.length) * 100).round()
          : 0;

      final stats = {
        'today': todayReports,
        'completed': completedReports,
        'late': lateReports,
        'completion_rate': completionRate,
        // Historical data for trends
        'yesterday': yesterdayReports,
        'last_week_completed': lastWeekCompleted,
        'last_month_late': lastMonthLate,
        'last_month_completion_rate': lastMonthCompletionRate,
      };

      emit(state.copyWith(
        status: HomeStatus.success,
        recentReports: recentReports,
        stats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handle the ReportFavoriteToggled event
  void _onReportFavoriteToggled(
    ReportFavoriteToggled event,
    Emitter<HomeState> emit,
  ) {
    // In a real app, this would update the favorite status in the database
    // For now, we'll just show how we would handle this event
    emit(state.copyWith(status: HomeStatus.success));
  }
}
