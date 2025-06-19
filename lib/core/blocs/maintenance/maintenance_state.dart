import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/maintenance_report_model.dart';

/// Status enum for the maintenance reports
enum MaintenanceStatus { initial, loading, success, failure }

/// State for the MaintenanceBloc
class MaintenanceState extends Equatable {
  final MaintenanceStatus status;
  final List<MaintenanceReport> reports;
  final String? filter;
  final String? searchQuery;
  final String? errorMessage;

  const MaintenanceState({
    this.status = MaintenanceStatus.initial,
    this.reports = const [],
    this.filter,
    this.searchQuery,
    this.errorMessage,
  });

  /// Get filtered reports based on search query and filter
  List<MaintenanceReport> get filteredReports {
    List<MaintenanceReport> result = List.from(reports);
    
    // Apply status filter if provided
    if (filter != null && filter!.isNotEmpty) {
      result = result.where((report) => report.status == filter).toList();
    }
    
    // Apply search query if provided
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((report) => 
        report.description.toLowerCase().contains(query) ||
        report.id.toLowerCase().contains(query) ||
        report.schoolId.toLowerCase().contains(query)
      ).toList();
    }
    
    return result;
  }

  @override
  List<Object?> get props => [status, reports, filter, searchQuery, errorMessage];

  /// Create a copy of this MaintenanceState with the given fields replaced with new values
  MaintenanceState copyWith({
    MaintenanceStatus? status,
    List<MaintenanceReport>? reports,
    String? filter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return MaintenanceState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
