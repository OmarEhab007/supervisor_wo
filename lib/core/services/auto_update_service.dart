import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import '../../presentation/widgets/modern_update_dialog.dart';

/// Completely isolated auto-update service
/// Does not interfere with existing app functionality
class AutoUpdateService {
  static AutoUpdateService? _instance;
  static const String _tableName = 'app_versions';

  Timer? _updateCheckTimer;
  bool _isInitialized = false;
  String? _currentVersion;
  BuildContext? _context;

  AutoUpdateService._();

  static AutoUpdateService get instance {
    _instance ??= AutoUpdateService._();
    return _instance!;
  }

  /// Initialize auto-update service (completely optional - won't break if fails)
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _context = context;
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      debugPrint('[AutoUpdate] 🚀 Starting initialization...');
      debugPrint('[AutoUpdate] 📱 Current app version: $_currentVersion');
      debugPrint('[AutoUpdate] 📱 Build number: ${packageInfo.buildNumber}');
      debugPrint('[AutoUpdate] 📱 Package name: ${packageInfo.packageName}');

      // Start periodic check (every 30 minutes)
      _startPeriodicUpdateCheck();

      // Initial check after 5 seconds (app fully loaded)
      Timer(const Duration(seconds: 5), () {
        debugPrint('[AutoUpdate] ⏰ Running initial update check...');
        _checkForUpdate();
      });

      _isInitialized = true;
      debugPrint('[AutoUpdate] ✅ Service initialized successfully!');
    } catch (error) {
      debugPrint('[AutoUpdate] ❌ Failed to initialize: $error');
      // Fail silently - app continues normally
    }
  }

  /// Start periodic update checks
  void _startPeriodicUpdateCheck() {
    _updateCheckTimer?.cancel();
    _updateCheckTimer = Timer.periodic(
      const Duration(minutes: 30), // Check every 30 minutes
      (_) => _checkForUpdate(),
    );
  }

  /// Check for updates (completely isolated operation)
  Future<void> _checkForUpdate() async {
    try {
      debugPrint('[AutoUpdate] 🔍 Starting update check...');

      if (_currentVersion == null) {
        debugPrint('[AutoUpdate] ❌ Current version is null');
        return;
      }

      if (_context == null || !_context!.mounted) {
        debugPrint('[AutoUpdate] ❌ Context is null or not mounted');
        return;
      }

      debugPrint('[AutoUpdate] 📡 Querying database for latest version...');
      final latestVersion = await _getLatestVersionFromDatabase();

      if (latestVersion == null) {
        debugPrint('[AutoUpdate] ❌ No version found in database');
        return;
      }

      debugPrint(
          '[AutoUpdate] 📊 Found version in database: ${latestVersion['version']}');
      debugPrint('[AutoUpdate] 📊 Current version: $_currentVersion');

      final hasUpdate =
          _compareVersions(_currentVersion!, latestVersion['version']) < 0;

      debugPrint(
          '[AutoUpdate] 🔍 Version comparison result: hasUpdate = $hasUpdate');
      debugPrint(
          '[AutoUpdate] 🔍 Comparison details: $_currentVersion vs ${latestVersion['version']}');

      if (hasUpdate && _context!.mounted) {
        debugPrint('[AutoUpdate] 🎉 Update available! Showing dialog...');
        _showUpdateDialog(latestVersion);
      } else if (!hasUpdate) {
        debugPrint('[AutoUpdate] ✅ App is up to date');
      }
    } catch (error) {
      debugPrint('[AutoUpdate] ❌ Update check failed: $error');
      // Fail silently - never interrupt user experience
    }
  }

  /// Get latest version from database (isolated query)
  Future<Map<String, dynamic>?> _getLatestVersionFromDatabase() async {
    try {
      debugPrint('[AutoUpdate] 🗄️ Executing database query...');
      debugPrint('[AutoUpdate] 🗄️ Table: $_tableName');

      final response = await SupabaseClientWrapper.client
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      debugPrint('[AutoUpdate] 🗄️ Database response: $response');
      debugPrint('[AutoUpdate] 🗄️ Response length: ${response.length}');

      if (response.isNotEmpty) {
        debugPrint('[AutoUpdate] 🗄️ Latest version data: ${response.first}');
        return response.first;
      } else {
        debugPrint('[AutoUpdate] 🗄️ No records found in database');
        return null;
      }
    } catch (error) {
      debugPrint('[AutoUpdate] ❌ Database query failed: $error');
      return null;
    }
  }

  /// Show update dialog (non-blocking)
  void _showUpdateDialog(Map<String, dynamic> versionInfo) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: true, // Always dismissible to not block user
      builder: (context) => ModernUpdateDialog(
        currentVersion: _currentVersion ?? 'Unknown',
        newVersion: versionInfo['version'] ?? 'Unknown',
        releaseNotes: versionInfo['release_notes'],
        downloadUrl: versionInfo['download_url'] ?? '',
      ),
    );
  }

  /// Download update (safe operation)
  Future<void> _downloadUpdate(String downloadUrl) async {
    try {
      final directUrl = _convertGoogleDriveUrl(downloadUrl);

      if (await canLaunchUrl(Uri.parse(directUrl))) {
        await launchUrl(
          Uri.parse(directUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AutoUpdate] Download failed: $error');
      }
      // Show simple error if context available
      if (_context?.mounted == true) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحميل التحديث. يرجى المحاولة لاحقاً.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Convert Google Drive URL to direct download
  String _convertGoogleDriveUrl(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match != null) {
        return 'https://drive.google.com/uc?export=download&id=${match.group(1)}';
      }
    }
    return url;
  }

  /// Simple version comparison
  int _compareVersions(String version1, String version2) {
    final v1Parts =
        version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts =
        version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part < v2Part) return -1;
      if (v1Part > v2Part) return 1;
    }
    return 0;
  }

  /// Manual update check (for testing or manual trigger)
  Future<void> manualUpdateCheck() async {
    await _checkForUpdate();
  }

  /// Dispose resources (call on app termination)
  void dispose() {
    _updateCheckTimer?.cancel();
    _updateCheckTimer = null;
    _isInitialized = false;
    _context = null;
  }
}
