import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/report_model.dart';

/// Status enum for ReportsState
enum ReportsStatus {
  initial,
  loading,
  success,
  failure,
}

/// Filter options for reports
enum ReportFilter {
  all,
  pending,
  completed,
  lateCompleted, // Late completed reports
  issues,
  recent,
  today, // Reports scheduled for today
  late, // Late reports
}

/// State for the ReportsBloc
class ReportsState extends Equatable {
  final ReportsStatus status;
  final List<Report> reports;
  final ReportFilter activeFilter;
  final String searchQuery;
  final String? errorMessage;
  // New: Pre-computed filtered lists for performance
  final List<Report> _cachedFilteredReports;
  final List<Report> _cachedUpcomingReports;

  const ReportsState({
    this.status = ReportsStatus.initial,
    this.reports = const [],
    this.activeFilter = ReportFilter.all,
    this.searchQuery = '',
    this.errorMessage,
    List<Report>? cachedFilteredReports,
    List<Report>? cachedUpcomingReports,
  })  : _cachedFilteredReports = cachedFilteredReports ?? const [],
        _cachedUpcomingReports = cachedUpcomingReports ?? const [];

  @override
  List<Object?> get props => [
        status,
        reports,
        activeFilter,
        searchQuery,
        errorMessage,
        _cachedFilteredReports,
        _cachedUpcomingReports,
      ];

  /// Create a copy of this ReportsState with the given fields replaced with new values
  ReportsState copyWith({
    ReportsStatus? status,
    List<Report>? reports,
    ReportFilter? activeFilter,
    String? searchQuery,
    String? errorMessage,
    List<Report>? cachedFilteredReports,
    List<Report>? cachedUpcomingReports,
  }) {
    return ReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      cachedFilteredReports: cachedFilteredReports ?? _cachedFilteredReports,
      cachedUpcomingReports: cachedUpcomingReports ?? _cachedUpcomingReports,
    );
  }

  /// Get pre-computed filtered reports based on activeFilter and searchQuery
  List<Report> get filteredReports => _cachedFilteredReports;

  /// Get pre-computed upcoming reports (for main reports button)
  List<Report> get upcomingReports => _cachedUpcomingReports;

  /// Legacy getter for backward compatibility - will be removed after refactoring
  @deprecated
  List<Report> get legacyFilteredReports {
    // First apply search filter if any
    final searchFiltered = searchQuery.isEmpty
        ? reports
        : reports
            .where((report) =>
                report.description
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                report.schoolName
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();

    // Get current date for today's reports filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Then apply status filter
    switch (activeFilter) {
      case ReportFilter.all:
        return searchFiltered;
      case ReportFilter.pending:
        // Only pending reports (not late)
        return searchFiltered
            .where((report) => report.status == 'pending')
            .toList();
      case ReportFilter.completed:
        return searchFiltered
            .where((report) => report.status == 'completed')
            .toList();
      case ReportFilter.lateCompleted:
        return searchFiltered
            .where((report) => report.status == 'late_completed')
            .toList();
      case ReportFilter.issues:
        // Include Late reports in the issues filter as well
        return searchFiltered
            .where((report) =>
                report.status == 'issues' || report.status == 'late')
            .toList();
      case ReportFilter.recent:
        // Sort by date and take the most recent ones
        final sorted = List<Report>.from(searchFiltered)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted.take(10).toList();
      case ReportFilter.today:
        // Reports scheduled for today that are not completed
        return searchFiltered.where((report) {
          final scheduledDate = DateTime(
            report.scheduledDate.year,
            report.scheduledDate.month,
            report.scheduledDate.day,
          );
          return scheduledDate.isAtSameMomentAs(today) &&
              report.status != 'completed';
        }).toList();
      case ReportFilter.late:
        // Only late reports
        return searchFiltered
            .where((report) => report.status == 'late')
            .toList();
    }
  }
}
