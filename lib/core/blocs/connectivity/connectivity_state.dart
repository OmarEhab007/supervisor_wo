import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/core/services/connectivity_service.dart';

/// Base state for connectivity
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

/// Initial state before connectivity is checked
class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

/// State when connectivity is being checked
class ConnectivityChecking extends ConnectivityState {
  const ConnectivityChecking();
}

/// State when device is connected to internet
class ConnectivityConnected extends ConnectivityState {
  final bool isSupabaseReachable;
  final DateTime lastChecked;
  
  const ConnectivityConnected({
    this.isSupabaseReachable = false,
    required this.lastChecked,
  });

  @override
  List<Object?> get props => [isSupabaseReachable, lastChecked];

  ConnectivityConnected copyWith({
    bool? isSupabaseReachable,
    DateTime? lastChecked,
  }) {
    return ConnectivityConnected(
      isSupabaseReachable: isSupabaseReachable ?? this.isSupabaseReachable,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

/// State when device has network but no internet
class ConnectivityLimited extends ConnectivityState {
  final DateTime lastChecked;
  
  const ConnectivityLimited({
    required this.lastChecked,
  });

  @override
  List<Object?> get props => [lastChecked];
}

/// State when device is disconnected from network
class ConnectivityDisconnected extends ConnectivityState {
  final DateTime lastChecked;
  final String? lastKnownError;
  
  const ConnectivityDisconnected({
    required this.lastChecked,
    this.lastKnownError,
  });

  @override
  List<Object?> get props => [lastChecked, lastKnownError];
}

/// State when connectivity status is unknown
class ConnectivityUnknown extends ConnectivityState {
  final String? error;
  final DateTime lastChecked;
  
  const ConnectivityUnknown({
    this.error,
    required this.lastChecked,
  });

  @override
  List<Object?> get props => [error, lastChecked];
}

/// Extension to get status from state
extension ConnectivityStateExtension on ConnectivityState {
  ConnectivityStatus get status {
    switch (runtimeType) {
      case ConnectivityConnected:
        return ConnectivityStatus.connected;
      case ConnectivityLimited:
        return ConnectivityStatus.limitedConnection;
      case ConnectivityDisconnected:
        return ConnectivityStatus.disconnected;
      default:
        return ConnectivityStatus.unknown;
    }
  }

  bool get isConnected => this is ConnectivityConnected;
  bool get hasNetworkConnection => 
      this is ConnectivityConnected || this is ConnectivityLimited;
  
  String get message {
    switch (runtimeType) {
      case ConnectivityConnected:
        final state = this as ConnectivityConnected;
        return state.isSupabaseReachable 
            ? 'Connected to internet and services'
            : 'Connected to internet';
      case ConnectivityLimited:
        return 'Connected to network but no internet access';
      case ConnectivityDisconnected:
        return 'No network connection';
      case ConnectivityChecking:
        return 'Checking connectivity...';
      default:
        return 'Connectivity status unknown';
    }
  }
} 