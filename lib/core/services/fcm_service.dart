import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/core/services/notification_services.dart';

/// FCM Service for handling push notifications
class FCMService {
  static FCMService? _instance;
  static const String _channelId = 'supervisor_reports_channel';
  static const String _channelName = 'Report Notifications';
  static const String _channelDescription =
      'Notifications for new reports and updates';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  FCMService._();

  static FCMService get instance {
    _instance ??= FCMService._();
    return _instance!;
  }

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM
      await _configureFCM();

      // Get and save FCM token
      await _getFCMToken();

      _isInitialized = true;
      _log('FCM service initialized successfully');
    } catch (error, stackTrace) {
      _log('Error initializing FCM service: $error');
      _log('Stack trace: $stackTrace');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _log('Notification permission granted: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _log('✅ Push notifications authorized');
      } else {
        _log('❌ Push notifications not authorized');
      }
    } catch (error) {
      _log('Error requesting permissions: $error');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization
      const androidInitialization =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const iosInitialization = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitialization,
        iOS: iosInitialization,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      _log('Local notifications initialized');
    } catch (error) {
      _log('Error initializing local notifications: $error');
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    var androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ledColor: Colors.blue,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Configure FCM handlers
  Future<void> _configureFCM() async {
    try {
      // Background message handler is now set up in main.dart

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app was terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _log('FCM handlers configured');
    } catch (error) {
      _log('Error configuring FCM: $error');
    }
  }

  /// Get FCM token and save to Supabase
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      _log('FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _saveFCMTokenToSupabase(_fcmToken!);
      }

      // Listen for token refresh - this ensures token is always up to date
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        _log('🔄 FCM Token refreshed: $newToken');
        try {
          await _saveFCMTokenToSupabase(newToken);
          _log('✅ New FCM token saved to database successfully');
        } catch (saveError) {
          _log('❌ Error saving refreshed FCM token: $saveError');
          // Retry after a delay
          Future.delayed(const Duration(seconds: 5), () {
            _saveFCMTokenToSupabase(newToken);
          });
        }
      });
    } catch (error) {
      _log('Error getting FCM token: $error');
    }
  }

  /// Save FCM token to Supabase for server-side notifications
  Future<void> _saveFCMTokenToSupabase(String token) async {
    try {
      final userId = SupabaseClientWrapper.client.auth.currentUser?.id;
      if (userId == null) {
        _log('⚠️ Cannot save FCM token: No authenticated user');
        return;
      }

      if (token.isEmpty) {
        _log('⚠️ Cannot save empty FCM token');
        return;
      }

      // Check if user already has a token (works with existing table structure)
      final existingTokens = await SupabaseClientWrapper.client
          .from('user_fcm_tokens')
          .select('id')
          .eq('user_id', userId);

      if (existingTokens.isNotEmpty) {
        // Update existing token
        await SupabaseClientWrapper.client
            .from('user_fcm_tokens')
            .update({
              'fcm_token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // Insert new token
        await SupabaseClientWrapper.client
            .from('user_fcm_tokens')
            .insert({
              'user_id': userId,
              'fcm_token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      _log('✅ FCM token saved to Supabase for user: $userId');
      _log('📱 Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
      
      // Optional: Clean up old tokens for this user (keep only the latest)
      await _cleanupOldTokens(userId, token);
      
    } catch (error) {
      _log('❌ Error saving FCM token to Supabase: $error');
      
      // Check if it's a table not found error
      if (error.toString().contains('relation "user_fcm_tokens" does not exist')) {
        _log('💡 Hint: You need to create the user_fcm_tokens table in Supabase');
        _log('💡 SQL: CREATE TABLE user_fcm_tokens (id UUID DEFAULT gen_random_uuid() PRIMARY KEY, user_id UUID REFERENCES auth.users(id), fcm_token TEXT NOT NULL, platform TEXT NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(user_id));');
      }
      
      throw error; // Re-throw to trigger retry logic
    }
  }

  /// Clean up old FCM tokens for a user (optional - keeps only the latest token)
  Future<void> _cleanupOldTokens(String userId, String currentToken) async {
    try {
      // Delete any old tokens for this user that are not the current token
      await SupabaseClientWrapper.client
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', userId)
          .neq('fcm_token', currentToken);
      
      _log('🧹 Cleaned up old FCM tokens for user');
    } catch (error) {
      _log('⚠️ Could not clean up old tokens: $error');
      // This is not critical, so we don't throw
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _log('📱 Foreground message received: ${message.messageId}');
    _log('Title: ${message.notification?.title}');
    _log('Body: ${message.notification?.body}');
    _log('Data: ${message.data}');

    // Show local notification when app is in foreground
    _showLocalNotification(message);

    // Add to in-app notification system
    // _addToInAppNotifications(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _log('🔔 Notification tapped: ${message.messageId}');

    // Navigate to appropriate screen based on notification data
    _navigateBasedOnNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Determine notification type and icon
      final notificationType = message.data['type'] ?? 'default';
      String iconPath = '@mipmap/ic_launcher';

      if (notificationType == 'emergency') {
        iconPath = '@drawable/ic_emergency'; // You'll need to add this
      }

      var androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
        autoCancel: true,
        ongoing: false,
        styleInformation: const BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      var platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: jsonEncode(message.data),
      );

      _log('Local notification shown');
    } catch (error) {
      _log('Error showing local notification: $error');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _log('🔔 Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _navigateBasedOnData(data);
      } catch (error) {
        _log('Error parsing notification payload: $error');
      }
    }
  }

  /// Add to in-app notification system
  // void _addToInAppNotifications(RemoteMessage message) {
  //   try {
  //     final notification = message.notification;
  //     if (notification == null) return;

  //     // Create AppNotification using the public method
  //     final appNotification =
  //         NotificationService.instance.createNotificationFromFCM(
  //       id: message.messageId ??
  //           DateTime.now().millisecondsSinceEpoch.toString(),
  //       title: notification.title ?? 'Notification',
  //       message: notification.body ?? '',
  //       data: message.data,
  //     );

  //     // Add to notification service using public method
  //     NotificationService.instance.addExternalNotification(appNotification);

  //     _log('Added FCM notification to in-app system');
  //   } catch (error) {
  //     _log('Error adding to in-app notifications: $error');
  //   }
  // }

  /// Get notification type from message data
  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_report':
        return NotificationType.newReport;
      case 'emergency':
        return NotificationType.emergency;
      case 'report_completed':
        return NotificationType.reportCompleted;
      case 'report_updated':
        return NotificationType.reportUpdated;
      case 'maintenance':
        return NotificationType.maintenance;
      default:
        return NotificationType.newReport;
    }
  }

  /// Navigate based on notification
  void _navigateBasedOnNotification(RemoteMessage message) {
    _navigateBasedOnData(message.data);
  }

  /// Navigate based on notification data
  void _navigateBasedOnData(Map<String, dynamic> data) {
    // This will be handled by your main app's navigation
    // You can use a global navigator key or event bus
    _log('Navigation data: $data');

    // Example: You could use an event bus or global navigator
    // EventBus.instance.fire(NavigateToReport(data['report_id']));
  }

  /// Send test notification (for debugging)
  Future<void> sendTestNotification() async {
    if (_fcmToken == null) {
      _log('No FCM token available for test');
      return;
    }

    // This would be called from your web app or server
    // For testing, you can use Firebase Console to send test messages
    _log('FCM Token for testing: $_fcmToken');
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;

  /// Manually refresh FCM token (useful when user logs in/out)
  Future<void> refreshToken() async {
    try {
      _log('🔄 Manually refreshing FCM token...');
      
      // Delete the old token first
      await _firebaseMessaging.deleteToken();
      
      // Get a new token
      final newToken = await _firebaseMessaging.getToken();
      if (newToken != null) {
        _fcmToken = newToken;
        _log('🆕 New FCM token obtained: $newToken');
        await _saveFCMTokenToSupabase(newToken);
        _log('✅ FCM token refresh completed successfully');
      } else {
        _log('❌ Failed to get new FCM token');
      }
    } catch (error) {
      _log('❌ Error refreshing FCM token: $error');
    }
  }

  /// Update token when user authentication state changes
  Future<void> updateTokenForUser(String? userId) async {
    if (userId == null) {
      _log('🔒 User logged out - FCM token will not be saved');
      return;
    }
    
    if (_fcmToken != null) {
      _log('👤 User logged in - updating FCM token for user: $userId');
      await _saveFCMTokenToSupabase(_fcmToken!);
    } else {
      _log('⚠️ No FCM token available to update for user: $userId');
      // Try to get a new token
      await _getFCMToken();
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _log('Subscribed to topic: $topic');
    } catch (error) {
      _log('Error subscribing to topic: $error');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _log('Unsubscribed from topic: $topic');
    } catch (error) {
      _log('Error unsubscribing from topic: $error');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FCMService] $message');
    }
  }

  /// Test Firebase initialization
  static Future<void> testFirebaseInit() async {
    try {
      debugPrint('🧪 Testing Firebase initialization...');

      // Check if Firebase is initialized
      final app = Firebase.app();
      debugPrint('✅ Firebase app found: ${app.name}');
      debugPrint('✅ Project ID: ${app.options.projectId}');
      debugPrint('✅ App ID: ${app.options.appId}');
    } catch (error) {
      debugPrint('❌ Firebase test failed: $error');

      // Try to initialize
      try {
        debugPrint('🔄 Attempting to initialize Firebase...');
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized successfully');
      } catch (initError) {
        debugPrint('❌ Firebase initialization failed: $initError');
      }
    }
  }
}
