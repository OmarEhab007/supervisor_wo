import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/core/utils/app_exception.dart' as app_exceptions;

/// Notification types
enum NotificationType {
  newReport,
  reportUpdated,
  reportCompleted,
  emergency,
  maintenance,
}

/// Notification data model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.newReport,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      data: data,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Lightweight notification service - FCM push notifications only
/// Does NOT store notifications locally or in database
class NotificationService {
  static NotificationService? _instance;

  // Supabase realtime subscription for new reports only
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _maintenanceChannel;

  bool _isInitialized = false;
  String? _currentUserId;

  NotificationService._();

  /// Get singleton instance
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  /// Initialize the lightweight notification service
  Future<void> init({String? userId}) async {
    if (_isInitialized) return;

    try {
      _currentUserId =
          userId ?? SupabaseClientWrapper.client.auth.currentUser?.id;

      if (_currentUserId == null) {
        _log('Cannot initialize notifications: no authenticated user');
        return;
      }

      // Only initialize realtime subscriptions for FCM push notifications
      await _initializeRealtimeSubscriptions();

      _isInitialized = true;
      _log(
          'Lightweight notification service initialized for user: $_currentUserId');
      _log('✅ Only FCM push notifications enabled - no local storage');
    } catch (error, stackTrace) {
      _log('Error initializing notification service: $error');
      throw app_exceptions.ErrorHandler.convertException(error, stackTrace);
    }
  }

  /// Initialize Supabase realtime subscriptions
  Future<void> _initializeRealtimeSubscriptions() async {
    try {
      final client = SupabaseClientWrapper.client;

      // Test realtime connection first
      _log('🔍 Testing realtime connection...');

      // Verify user is authenticated
      final user = client.auth.currentUser;
      if (user == null) {
        _log('❌ No authenticated user for realtime subscription');
        return;
      }

      _log('✅ User authenticated: ${user.id}');

      // Create channels with better error handling
      try {
        // Subscribe to reports table for new reports
        _reportsChannel = client
            .channel('reports_changes_${DateTime.now().millisecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'reports',
              callback: _handleReportInsert,
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'reports',
              callback: _handleReportUpdate,
            );

        // Subscribe to maintenance reports
        _maintenanceChannel = client
            .channel(
                'maintenance_reports_changes_${DateTime.now().millisecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'maintenance_reports',
              callback: _handleMaintenanceReportInsert,
            );

        _log('📡 Channels created, attempting subscriptions...');

        // Subscribe to the channels with detailed logging
        try {
          _log('🔗 Subscribing to reports channel...');
          await _reportsChannel?.subscribe();
          _log('✅ Reports channel subscription completed');
        } catch (e) {
          _log('❌ Reports channel subscription error: $e');
        }

        try {
          _log('🔗 Subscribing to maintenance channel...');
          await _maintenanceChannel?.subscribe();
          _log('✅ Maintenance channel subscription completed');
        } catch (e) {
          _log('❌ Maintenance channel subscription error: $e');
        }

        _log('✅ All realtime subscriptions completed');

        // Monitor connection status
        _startConnectionMonitoring();

        // Test connection after a short delay
        Future.delayed(const Duration(seconds: 3), () {
          _testRealtimeConnection();
        });
      } catch (subscriptionError) {
        _log('❌ Error during channel subscription: $subscriptionError');
        // Clean up failed channels
        await _cleanupRealtimeChannels();

        // Retry after delay
        Future.delayed(const Duration(seconds: 10), () {
          _log('🔄 Retrying realtime subscription...');
          _initializeRealtimeSubscriptions();
        });
      }
    } catch (error, stackTrace) {
      _log('❌ Error initializing realtime subscriptions: $error');
      _log('Stack trace: $stackTrace');
    }
  }

  /// Monitor realtime connection status
  void _startConnectionMonitoring() {
    // Check connection status every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      _checkConnectionStatus();
    });
  }

  /// Check if realtime connection is still active
  void _checkConnectionStatus() {
    try {
      final client = SupabaseClientWrapper.client;
      final user = client.auth.currentUser;

      if (user == null) {
        _log('⚠️ User session lost - reinitializing...');
        _initializeRealtimeSubscriptions();
        return;
      }

      // Test if channels are still active by checking their state
      bool needsReconnection = false;

      if (_reportsChannel == null || _maintenanceChannel == null) {
        _log('⚠️ Some channels are null - reconnecting...');
        needsReconnection = true;
      }

      if (needsReconnection) {
        _log('🔄 Reconnecting realtime subscriptions...');
        _initializeRealtimeSubscriptions();
      } else {
        _log('✅ Realtime connection status check passed');
      }
    } catch (error) {
      _log('❌ Connection status check failed: $error');
    }
  }

  /// Test realtime connection with a simple method
  void _testRealtimeConnection() {
    _log('🧪 Testing realtime connection...');

    // Just log that the connection test is happening, don't create notifications
    _log('✅ Realtime connection test completed');
  }

  /// Clean up realtime channels
  Future<void> _cleanupRealtimeChannels() async {
    try {
      await _reportsChannel?.unsubscribe();
      await _maintenanceChannel?.unsubscribe();

      _reportsChannel = null;
      _maintenanceChannel = null;

      _log('🧹 Realtime channels cleaned up');
    } catch (error) {
      _log('Error cleaning up channels: $error');
    }
  }

  /// Handle new report insertion - FCM push only, no storage
  void _handleReportInsert(PostgresChangePayload payload) {
    try {
      _log('🔥 NEW REPORT EVENT RECEIVED!');
      _log('Event type: ${payload.eventType}');
      _log('Table: ${payload.table}');

      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) {
        _log('❌ Empty record received');
        return;
      }

      // Check if this report is relevant to current user
      final supervisorId = newRecord['supervisor_id'] as String?;
      final currentUserId = _currentUserId;

      _log('Report supervisor_id: $supervisorId');
      _log('Current user_id: $currentUserId');

      if (supervisorId != currentUserId) {
        _log('ℹ️ Report not for current user - skipping notification');
        return;
      }

      _log('✅ Report is for current user - sending FCM push notification');

      // 🚫 DISABLED: Don't send FCM from Flutter app - dashboard handles this
      _log(
          '⚠️ FCM sending disabled in Flutter app - dashboard handles notifications');
      // _sendFCMPushNotification(newRecord, 'new_report');

      _log('✅ FCM push notification sent for new report');
    } catch (error, stackTrace) {
      _log('❌ Error handling report insert: $error');
      _log('Stack trace: $stackTrace');
    }
  }

  /// Handle report updates
  void _handleReportUpdate(PostgresChangePayload payload) {
    try {
      _log('🔄 REPORT UPDATE EVENT RECEIVED!');
      _log('Event type: ${payload.eventType}');
      _log('Table: ${payload.table}');

      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      if (newRecord.isEmpty || oldRecord.isEmpty) {
        _log('❌ Empty records received');
        return;
      }

      // Check if this report is relevant to current user
      final supervisorId = newRecord['supervisor_id'] as String?;
      final currentUserId = _currentUserId;

      _log('Report supervisor_id: $supervisorId');
      _log('Current user_id: $currentUserId');

      if (supervisorId != currentUserId) {
        _log('ℹ️ Report update not for current user - skipping notification');
        return;
      }

      // Check if status changed to completed
      final oldStatus = oldRecord['status'] as String?;
      final newStatus = newRecord['status'] as String?;

      _log('Status change: $oldStatus -> $newStatus');

      NotificationType type = NotificationType.reportUpdated;
      if (oldStatus != 'completed' && newStatus == 'completed') {
        type = NotificationType.reportCompleted;
      }

      final notification = _createNotificationFromReport(newRecord, type);
      _log('✅ Report update notification created: ${notification.title}');

      // Show immediate feedback to user
      _createSystemNotification('📝 تحديث بلاغ',
          'تم تحديث بلاغ في مدرسة ${notification.data['school_name']}');
    } catch (error, stackTrace) {
      _log('❌ Error handling report update: $error');
      _log('Stack trace: $stackTrace');
    }
  }

  /// Handle maintenance report insertion - FCM push only, no storage
  void _handleMaintenanceReportInsert(PostgresChangePayload payload) {
    try {
      _log('🔧 MAINTENANCE REPORT EVENT RECEIVED!');
      _log('Event type: ${payload.eventType}');
      _log('Table: ${payload.table}');

      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) {
        _log('❌ Empty maintenance record received');
        return;
      }

      final supervisorId = newRecord['supervisor_id'] as String?;
      final currentUserId = _currentUserId;

      _log('Maintenance supervisor_id: $supervisorId');
      _log('Current user_id: $currentUserId');

      if (supervisorId != currentUserId) {
        _log(
            'ℹ️ Maintenance report not for current user - skipping notification');
        return;
      }

      _log(
          '✅ Maintenance report is for current user - sending FCM push notification');

      // 🚫 DISABLED: Don't send FCM from Flutter app - dashboard handles this
      _log(
          '⚠️ FCM sending disabled in Flutter app - dashboard handles notifications');
      // _sendFCMPushNotification(newRecord, 'maintenance');

      _log('✅ FCM push notification sent for maintenance report');
    } catch (error, stackTrace) {
      _log('❌ Error handling maintenance report insert: $error');
      _log('Stack trace: $stackTrace');
    }
  }

  /// Create notification from report data
  AppNotification _createNotificationFromReport(
    Map<String, dynamic> reportData,
    NotificationType type,
  ) {
    final schoolName =
        reportData['school_name'] as String? ?? 'مدرسة غير معروفة';
    final priority = reportData['priority'] as String? ?? 'روتيني';
    final isEmergency = priority.toLowerCase() == 'high' ||
        priority.toLowerCase() == 'emergency';

    String title;
    String message;

    switch (type) {
      case NotificationType.newReport:
        title = isEmergency ? '🚨 بلاغ عاجل' : 'بلاغ جديد';
        message = 'لديك بلاغ جديد في مدرسة $schoolName .. الأولوية $priority';
        break;
      case NotificationType.reportCompleted:
        title = '✅ تم إنجاز البلاغ';
        message = 'تم إنجاز البلاغ في مدرسة $schoolName';
        break;
      case NotificationType.reportUpdated:
        title = '📝 تم تحديث البلاغ';
        message = 'تم تحديث البلاغ في مدرسة $schoolName';
        break;
      default:
        title = 'بلاغ جديد';
        message = 'لديك بلاغ جديد في مدرسة $schoolName .. الأولوية $priority';
    }

    // Ensure school_name is included in data for navigation
    final enhancedData = Map<String, dynamic>.from(reportData);
    enhancedData['school_name'] = schoolName;
    enhancedData['schoolName'] =
        schoolName; // Alternative key for compatibility
    // Store emergency status in data instead of changing the type
    enhancedData['is_emergency'] = isEmergency;
    enhancedData['priority'] = priority;

    return AppNotification(
      id: reportData['id'] as String,
      type:
          type, // Always use the original type (newReport) - don't change to emergency
      title: title,
      message: message,
      data: enhancedData,
      timestamp: DateTime.now(),
    );
  }

  /// Send FCM push notification directly without storing anything
  Future<void> _sendFCMPushNotification(
      Map<String, dynamic> reportData, String reportType) async {
    try {
      final client = SupabaseClientWrapper.client;

      final schoolName =
          reportData['school_name'] as String? ?? 'مدرسة غير معروفة';
      final priority = reportData['priority'] as String? ?? 'روتيني';
      final reportId = reportData['id'] as String;

      // Determine notification details
      final isEmergency = priority.toLowerCase() == 'high' ||
          priority.toLowerCase() == 'emergency';

      String title;
      String body;

      if (reportType == 'maintenance') {
        title = 'صيانة دورية 🔧';
        body = 'لديك طلب صيانة جديد في مدرسة $schoolName';
      } else {
        title = isEmergency ? 'بلاغ عاجل 🚨' : 'بلاغ جديد 📋';
        body = 'لديك بلاغ جديد في مدرسة $schoolName .. الأولوية $priority';
      }

      // Send FCM notification via edge function
      final response = await client.functions.invoke(
        'send_notification',
        body: {
          'user_id': _currentUserId,
          'title': title,
          'body': body,
          'priority': priority,
          'school_name': schoolName,
          'data': {
            'type': reportType,
            'report_id': reportId,
            'school_name': schoolName,
            'priority': priority,
            'is_emergency': isEmergency.toString(),
          },
        },
      );

      if (response.status == 200) {
        _log('✅ FCM push notification sent successfully');
      } else {
        _log('❌ FCM push notification failed: ${response.status}');
      }
    } catch (error) {
      _log('❌ Error sending FCM push notification: $error');
    }
  }

  /// Create system notification helper
  void _createSystemNotification(String title, String message) {
    // Do nothing - debugging notifications disabled
    _log('System notification suppressed: $title - $message');
  }

  /// Dispose the service
  void dispose() {
    _reportsChannel?.unsubscribe();
    _maintenanceChannel?.unsubscribe();
    _isInitialized = false;
    _log('Lightweight notification service disposed');
  }

  /// Log messages
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationService] $message');
    }
  }
}
