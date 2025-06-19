import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/connectivity/connectivity_event.dart';
import 'package:supervisor_wo/core/blocs/connectivity/connectivity_state.dart';
import 'package:supervisor_wo/core/services/connectivity_service.dart';

/// Bloc for managing connectivity state throughout the app
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  
  ConnectivityBloc({
    ConnectivityService? connectivityService,
  }) : _connectivityService = connectivityService ?? ConnectivityService.instance,
       super(const ConnectivityInitial()) {
    
    // Register event handlers
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityStatusChanged>(_onStatusChanged);
    on<ConnectivityCheckRequested>(_onCheckRequested);
    on<ConnectivityRetryRequested>(_onRetryRequested);
    on<ConnectivitySupabaseTestRequested>(_onSupabaseTestRequested);
  }

  /// Handle bloc initialization
  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    try {
      emit(const ConnectivityChecking());
      
      // Initialize connectivity service
      await _connectivityService.initialize();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivityService.connectivityStream.listen(
        (status) => add(ConnectivityStatusChanged(status)),
      );
      
      // Emit initial state based on current status
      final currentStatus = _connectivityService.currentStatus;
      await _emitStateFromStatus(currentStatus, emit);
      
    } catch (error) {
      debugPrint('[ConnectivityBloc] Initialization error: $error');
      emit(ConnectivityUnknown(
        error: error.toString(),
        lastChecked: DateTime.now(),
      ));
    }
  }

  /// Handle connectivity status changes
  Future<void> _onStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    await _emitStateFromStatus(event.status, emit);
  }

  /// Handle manual connectivity check requests
  Future<void> _onCheckRequested(
    ConnectivityCheckRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    try {
      emit(const ConnectivityChecking());
      
      await _connectivityService.forceConnectivityCheck();
      final currentStatus = _connectivityService.currentStatus;
      
      await _emitStateFromStatus(currentStatus, emit);
      
    } catch (error) {
      debugPrint('[ConnectivityBloc] Check request error: $error');
      emit(ConnectivityUnknown(
        error: error.toString(),
        lastChecked: DateTime.now(),
      ));
    }
  }

  /// Handle retry requests for failed operations
  Future<void> _onRetryRequested(
    ConnectivityRetryRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    try {
      emit(const ConnectivityChecking());
      
      // Force a fresh connectivity check
      await _connectivityService.forceConnectivityCheck();
      
      // Test Supabase connectivity if we have internet
      final currentStatus = _connectivityService.currentStatus;
      if (currentStatus == ConnectivityStatus.connected) {
        final isSupabaseReachable = await _connectivityService.isSupabaseReachable();
        emit(ConnectivityConnected(
          isSupabaseReachable: isSupabaseReachable,
          lastChecked: DateTime.now(),
        ));
      } else {
        await _emitStateFromStatus(currentStatus, emit);
      }
      
    } catch (error) {
      debugPrint('[ConnectivityBloc] Retry error: $error');
      emit(ConnectivityUnknown(
        error: error.toString(),
        lastChecked: DateTime.now(),
      ));
    }
  }

  /// Handle Supabase connectivity test requests
  Future<void> _onSupabaseTestRequested(
    ConnectivitySupabaseTestRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    try {
      if (state is ConnectivityConnected) {
        final currentState = state as ConnectivityConnected;
        
        // Test Supabase connectivity
        final isSupabaseReachable = await _connectivityService.isSupabaseReachable();
        
        emit(currentState.copyWith(
          isSupabaseReachable: isSupabaseReachable,
          lastChecked: DateTime.now(),
        ));
      } else {
        // If not connected, perform full connectivity check
        add(const ConnectivityCheckRequested());
      }
      
    } catch (error) {
      debugPrint('[ConnectivityBloc] Supabase test error: $error');
      if (state is ConnectivityConnected) {
        final currentState = state as ConnectivityConnected;
        emit(currentState.copyWith(
          isSupabaseReachable: false,
          lastChecked: DateTime.now(),
        ));
      }
    }
  }

  /// Emit appropriate state based on connectivity status
  Future<void> _emitStateFromStatus(
    ConnectivityStatus status,
    Emitter<ConnectivityState> emit,
  ) async {
    final now = DateTime.now();
    
    switch (status) {
      case ConnectivityStatus.connected:
        // Test Supabase connectivity when we have internet
        try {
          final isSupabaseReachable = await _connectivityService.isSupabaseReachable();
          emit(ConnectivityConnected(
            isSupabaseReachable: isSupabaseReachable,
            lastChecked: now,
          ));
        } catch (error) {
          // If Supabase test fails, still show as connected but without Supabase
          debugPrint('[ConnectivityBloc] Supabase test failed: $error');
          emit(ConnectivityConnected(
            isSupabaseReachable: false,
            lastChecked: now,
          ));
        }
        break;
        
      case ConnectivityStatus.limitedConnection:
        emit(ConnectivityLimited(lastChecked: now));
        break;
        
      case ConnectivityStatus.disconnected:
        emit(ConnectivityDisconnected(lastChecked: now));
        break;
        
      case ConnectivityStatus.unknown:
        emit(ConnectivityUnknown(lastChecked: now));
        break;
    }
  }

  /// Get user-friendly error message for network issues
  String getNetworkErrorMessage() {
    switch (state.runtimeType) {
      case ConnectivityDisconnected:
        return 'No internet connection. Please check your network settings and try again.';
      case ConnectivityLimited:
        return 'Limited connectivity. Please check your internet connection.';
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        if (!connectedState.isSupabaseReachable) {
          return 'Service temporarily unavailable. Please try again later.';
        }
        return 'Connected to all services.';
      default:
        return 'Connection status unknown. Please try again.';
    }
  }

  /// Check if network operations should be allowed
  bool get canPerformNetworkOperations {
    return state is ConnectivityConnected;
  }

  /// Check if Supabase operations should be allowed
  bool get canPerformSupabaseOperations {
    if (state is ConnectivityConnected) {
      final connectedState = state as ConnectivityConnected;
      return connectedState.isSupabaseReachable;
    }
    return false;
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
} 