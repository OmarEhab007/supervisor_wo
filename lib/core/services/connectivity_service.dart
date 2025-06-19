import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Enum representing different network connectivity states
enum ConnectivityStatus {
  /// Device is connected to the internet
  connected,
  
  /// Device is connected to a network but no internet access
  limitedConnection,
  
  /// Device is not connected to any network
  disconnected,
  
  /// Connectivity status is unknown
  unknown,
}

/// Service for monitoring network connectivity and internet accessibility
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  final StreamController<ConnectivityStatus> _statusController = 
      StreamController<ConnectivityStatus>.broadcast();
  
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _pingTimer;
  bool _isInitialized = false;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get connectivityStream => _statusController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Check if device has internet connectivity
  bool get isConnected => _currentStatus == ConnectivityStatus.connected;

  /// Check if device has any network connection (even without internet)
  bool get hasNetworkConnection => 
      _currentStatus == ConnectivityStatus.connected || 
      _currentStatus == ConnectivityStatus.limitedConnection;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity status
      await _checkConnectivity();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          debugPrint('[ConnectivityService] Error listening to connectivity: $error');
        },
      );

      // Start periodic internet connectivity checks
      _startPeriodicConnectivityCheck();

      _isInitialized = true;
      debugPrint('[ConnectivityService] Initialized successfully');
    } catch (error) {
      debugPrint('[ConnectivityService] Initialization failed: $error');
      // Set status to unknown if initialization fails
      _updateStatus(ConnectivityStatus.unknown);
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    debugPrint('[ConnectivityService] Connectivity changed: $results');
    await _checkConnectivity();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      debugPrint('[ConnectivityService] Checking connectivity: $connectivityResults');

      // Check if device has any network connection
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _updateStatus(ConnectivityStatus.disconnected);
        return;
      }

      // Device has network connection, now check internet accessibility
      final hasInternet = await _checkInternetConnectivity();
      if (hasInternet) {
        _updateStatus(ConnectivityStatus.connected);
      } else {
        _updateStatus(ConnectivityStatus.limitedConnection);
      }
    } catch (error) {
      debugPrint('[ConnectivityService] Error checking connectivity: $error');
      _updateStatus(ConnectivityStatus.unknown);
    }
  }

  /// Check if device can actually reach the internet
  Future<bool> _checkInternetConnectivity() async {
    try {
      // Test multiple endpoints for reliability
      final List<String> testUrls = [
        'https://www.google.com',
        'https://www.cloudflare.com',
        'https://httpbin.org/get',
      ];

      // Try each URL with a timeout
      for (final url in testUrls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {'Connection': 'close'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            debugPrint('[ConnectivityService] Internet check successful via $url');
            return true;
          }
        } catch (e) {
          debugPrint('[ConnectivityService] Failed to reach $url: $e');
          continue;
        }
      }

      // If all URLs fail, try a simple socket connection
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint('[ConnectivityService] Internet check successful via DNS lookup');
          return true;
        }
      } catch (e) {
        debugPrint('[ConnectivityService] DNS lookup failed: $e');
      }

      return false;
    } catch (error) {
      debugPrint('[ConnectivityService] Internet connectivity check failed: $error');
      return false;
    }
  }

  /// Update connectivity status and notify listeners
  void _updateStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      final oldStatus = _currentStatus;
      _currentStatus = status;
      
      debugPrint('[ConnectivityService] Status changed: $oldStatus -> $status');
      _statusController.add(status);

      // Log connectivity changes for debugging
      _logConnectivityChange(oldStatus, status);
    }
  }

  /// Log connectivity changes with timestamps
  void _logConnectivityChange(ConnectivityStatus from, ConnectivityStatus to) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[ConnectivityService] [$timestamp] Connectivity: $from -> $to');
    
    // You could send this to analytics or crash reporting service
    switch (to) {
      case ConnectivityStatus.connected:
        debugPrint('[ConnectivityService] ✅ Internet connection restored');
        break;
      case ConnectivityStatus.limitedConnection:
        debugPrint('[ConnectivityService] ⚠️ Network available but no internet access');
        break;
      case ConnectivityStatus.disconnected:
        debugPrint('[ConnectivityService] ❌ No network connection');
        break;
      case ConnectivityStatus.unknown:
        debugPrint('[ConnectivityService] ❓ Connectivity status unknown');
        break;
    }
  }

  /// Start periodic connectivity checks
  void _startPeriodicConnectivityCheck() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      _checkConnectivity();
    });
  }

  /// Force a connectivity check
  Future<void> forceConnectivityCheck() async {
    await _checkConnectivity();
  }

  /// Check if a specific host is reachable
  Future<bool> isHostReachable(String host, {int port = 80}) async {
    try {
      final socket = await Socket.connect(host, port)
          .timeout(const Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (e) {
      debugPrint('[ConnectivityService] Host $host:$port not reachable: $e');
      return false;
    }
  }

  /// Check if Supabase is reachable
  Future<bool> isSupabaseReachable() async {
    try {
      // Test Supabase connectivity
      final response = await http.get(
        Uri.parse('https://cftjaukrygtzguqcafon.supabase.co/rest/v1/'),
        headers: {
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmdGphdWtyeWd0emd1cWNhZm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMjU1NzYsImV4cCI6MjA2MzkwMTU3Nn0.28pIhi_qCDK3SIjCiJa0VuieFx0byoMK-wdmhb4G75c',
          'Connection': 'close',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 401; // 401 is expected without proper auth
    } catch (e) {
      debugPrint('[ConnectivityService] Supabase not reachable: $e');
      return false;
    }
  }

  /// Get connectivity status as human-readable string
  String getStatusMessage() {
    switch (_currentStatus) {
      case ConnectivityStatus.connected:
        return 'Connected to internet';
      case ConnectivityStatus.limitedConnection:
        return 'Connected to network but no internet access';
      case ConnectivityStatus.disconnected:
        return 'No network connection';
      case ConnectivityStatus.unknown:
        return 'Connectivity status unknown';
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _pingTimer?.cancel();
    _statusController.close();
    _isInitialized = false;
    debugPrint('[ConnectivityService] Disposed');
  }
} 