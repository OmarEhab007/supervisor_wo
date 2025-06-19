import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/core/services/connectivity_service.dart';

/// Base event for connectivity operations
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when the connectivity bloc is started
class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

/// Event triggered when connectivity status changes
class ConnectivityStatusChanged extends ConnectivityEvent {
  final ConnectivityStatus status;
  
  const ConnectivityStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Event to force a connectivity check
class ConnectivityCheckRequested extends ConnectivityEvent {
  const ConnectivityCheckRequested();
}

/// Event to retry failed network operations
class ConnectivityRetryRequested extends ConnectivityEvent {
  const ConnectivityRetryRequested();
}

/// Event to test Supabase connectivity specifically
class ConnectivitySupabaseTestRequested extends ConnectivityEvent {
  const ConnectivitySupabaseTestRequested();
} 