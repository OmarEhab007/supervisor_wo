import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';

/// Configuration class for late reports checker
class LateReportsCheckerConfig {
  final Duration checkInterval;
  final Duration initialDelay;
  final bool enabled;
  final bool runInBackground;

  const LateReportsCheckerConfig({
    this.checkInterval = const Duration(minutes: 30),
    this.initialDelay = const Duration(seconds: 10),
    this.enabled = true,
    this.runInBackground = true,
  });

  /// Default configuration for production
  static const production = LateReportsCheckerConfig(
    checkInterval: Duration(minutes: 30),
    initialDelay: Duration(seconds: 10),
    enabled: true,
    runInBackground: true,
  );

  /// Configuration for development with shorter intervals
  static const development = LateReportsCheckerConfig(
    checkInterval: Duration(minutes: 5),
    initialDelay: Duration(seconds: 5),
    enabled: true,
    runInBackground: false,
  );

  /// Configuration for testing (disabled)
  static const testing = LateReportsCheckerConfig(
    checkInterval: Duration(minutes: 1),
    initialDelay: Duration.zero,
    enabled: false,
    runInBackground: false,
  );
}

/// Service to periodically check for late reports
class LateReportsChecker {
  final ReportsBloc _reportsBloc;
  final LateReportsCheckerConfig _config;
  Timer? _timer;
  Timer? _initialTimer;
  bool _isRunning = false;
  bool _isDisposed = false;
  int _checkCount = 0;
  DateTime? _lastSuccessfulCheck;

  /// Creates a new LateReportsChecker with configuration
  LateReportsChecker({
    required ReportsBloc reportsBloc,
    LateReportsCheckerConfig? config,
    @Deprecated('Use config parameter instead') Duration? checkInterval,
  })  : _reportsBloc = reportsBloc,
        _config = config ??
            (checkInterval != null
                ? LateReportsCheckerConfig(checkInterval: checkInterval)
                : (kDebugMode
                    ? LateReportsCheckerConfig.development
                    : LateReportsCheckerConfig.production)) {
    if (_config.enabled) {
      _scheduleInitialCheck();
    }
  }

  /// Factory constructor for production environment
  factory LateReportsChecker.production(ReportsBloc reportsBloc) {
    return LateReportsChecker(
      reportsBloc: reportsBloc,
      config: LateReportsCheckerConfig.production,
    );
  }

  /// Factory constructor for development environment
  factory LateReportsChecker.development(ReportsBloc reportsBloc) {
    return LateReportsChecker(
      reportsBloc: reportsBloc,
      config: LateReportsCheckerConfig.development,
    );
  }

  /// Factory constructor for testing environment
  factory LateReportsChecker.testing(ReportsBloc reportsBloc) {
    return LateReportsChecker(
      reportsBloc: reportsBloc,
      config: LateReportsCheckerConfig.testing,
    );
  }

  /// Current configuration
  LateReportsCheckerConfig get config => _config;

  /// Whether the checker is currently running
  bool get isRunning => _isRunning;

  /// Whether the checker has been disposed
  bool get isDisposed => _isDisposed;

  /// Number of checks performed
  int get checkCount => _checkCount;

  /// Last successful check timestamp
  DateTime? get lastSuccessfulCheck => _lastSuccessfulCheck;

  /// Time until next check (if running)
  Duration? get timeUntilNextCheck {
    if (!_isRunning || _timer == null) return null;
    // This is an approximation since Timer doesn't expose remaining time
    return _config.checkInterval;
  }

  /// Schedule the initial check after the configured delay
  void _scheduleInitialCheck() {
    if (_isDisposed || !_config.enabled) return;

    _initialTimer = Timer(_config.initialDelay, () {
      if (!_isDisposed) {
        _startPeriodicChecks();
      }
    });
  }

  /// Start periodic checks for late reports
  void _startPeriodicChecks() {
    if (_isDisposed || !_config.enabled || _isRunning) return;

    _isRunning = true;

    // Perform initial check immediately
    _performCheck();

    // Set up periodic checks
    _timer = Timer.periodic(_config.checkInterval, (_) {
      if (!_isDisposed) {
        _performCheck();
      }
    });

    _log(
        'Late reports checker started with interval: ${_config.checkInterval}');
  }

  /// Perform a single check for late reports
  void _performCheck() {
    if (_isDisposed) return;

    try {
      _checkCount++;
      _reportsBloc.add(const ReportsCheckLateStatus());
      _lastSuccessfulCheck = DateTime.now();

      _log('Performed late reports check #$_checkCount');
    } catch (error) {
      _log('Error during late reports check: $error');
    }
  }

  /// Manually trigger a check for late reports
  void checkNow() {
    if (_isDisposed) {
      _log('Cannot perform manual check: checker is disposed');
      return;
    }

    if (!_config.enabled) {
      _log('Cannot perform manual check: checker is disabled');
      return;
    }

    _log('Manual check triggered');
    _performCheck();
  }

  /// Start the checker if it's not running
  void start() {
    if (_isDisposed) {
      _log('Cannot start: checker is disposed');
      return;
    }

    if (!_config.enabled) {
      _log('Cannot start: checker is disabled');
      return;
    }

    if (!_isRunning) {
      _log('Starting late reports checker');
      _startPeriodicChecks();
    }
  }

  /// Pause the checker (can be resumed with start())
  void pause() {
    if (_isRunning) {
      _log('Pausing late reports checker');
      _stopTimers();
      _isRunning = false;
    }
  }

  /// Stop all timers
  void _stopTimers() {
    _timer?.cancel();
    _timer = null;
    _initialTimer?.cancel();
    _initialTimer = null;
  }

  /// Stop and dispose the checker
  void dispose() {
    if (_isDisposed) return;

    _log('Disposing late reports checker');
    _stopTimers();
    _isRunning = false;
    _isDisposed = true;
  }

  /// Reset the checker (restart with fresh state)
  void reset() {
    if (_isDisposed) {
      _log('Cannot reset: checker is disposed');
      return;
    }

    _log('Resetting late reports checker');
    pause();
    _checkCount = 0;
    _lastSuccessfulCheck = null;

    if (_config.enabled) {
      start();
    }
  }

  /// Log messages with prefix
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LateReportsChecker] $message');
    }
  }

  @override
  String toString() {
    return 'LateReportsChecker('
        'enabled: ${_config.enabled}, '
        'running: $_isRunning, '
        'disposed: $_isDisposed, '
        'checks: $_checkCount, '
        'interval: ${_config.checkInterval}'
        ')';
  }
}
