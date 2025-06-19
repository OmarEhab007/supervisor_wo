import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/models/report_model.dart';

/// Status enum for HomeState
enum HomeStatus {
  initial,
  loading,
  success,
  failure,
}

/// State for the HomeBloc
class HomeState extends Equatable {
  final HomeStatus status;
  final List<Report> recentReports;
  final Map<String, int> stats;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.recentReports = const [],
    this.stats = const {},
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, recentReports, stats, errorMessage];

  /// Create a copy of this HomeState with the given fields replaced with new values
  HomeState copyWith({
    HomeStatus? status,
    List<Report>? recentReports,
    Map<String, int>? stats,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      recentReports: recentReports ?? this.recentReports,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }
}
