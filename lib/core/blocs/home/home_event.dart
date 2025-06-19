import 'package:equatable/equatable.dart';

/// Base class for all HomeBloc events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the initial data for the home screen
class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// Event when the home screen is refreshed
class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}

/// Event when a report is marked as favorite
class ReportFavoriteToggled extends HomeEvent {
  final String reportId;
  final bool isFavorite;

  const ReportFavoriteToggled({
    required this.reportId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [reportId, isFavorite];
}
