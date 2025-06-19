import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supervisor_wo/core/blocs/app_bloc_observer.dart';
import 'package:supervisor_wo/core/repositories/auth_repository.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';
import 'package:supervisor_wo/core/repositories/school_repository.dart';
import 'package:supervisor_wo/core/services/fcm_service.dart';
import 'package:supervisor_wo/core/services/connectivity_service.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/core/utils/app_exception.dart';

import 'notification_services.dart';

/// Container for all initialized repositories
class AppRepositories {
  final ReportRepository reportRepository;
  final SchoolRepository schoolRepository;
  final AuthRepository authRepository;

  const AppRepositories({
    required this.reportRepository,
    required this.schoolRepository,
    required this.authRepository,
  });
}

/// Service for handling app initialization
class AppInitializer {
  static const String _supabaseUrl = 'https://cftjaukrygtzguqcafon.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmdGphdWtyeWd0emd1cWNhZm9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMjU1NzYsImV4cCI6MjA2MzkwMTU3Nn0.28pIhi_qCDK3SIjCiJa0VuieFx0byoMK-wdmhb4G75c';

  /// Initialize the entire application
  static Future<AppRepositories> initializeApp() async {
    try {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Set up error handling
      await _setupErrorHandling();

      // Set up BLoC observer
      _setupBlocObserver();

      // Initialize Firebase FIRST (before any other Firebase services)
      await _initializeFirebase();

      // Initialize connectivity service
      await _initializeConnectivityService();

      // Initialize Supabase
      await _initializeSupabase();

      // Initialize repositories
      final repositories = await _initializeRepositories();

      // Setup database
      await _setupDatabase(repositories.authRepository);

      // Initialize core services asynchronously to avoid blocking startup
      // OPTION 1: Current approach (recommended) - processes notifications in background
      // _initializeBackgroundServices();
      
      // OPTION 2: Services only - real-time notifications only, no old queue processing
      _initializeServicesOnly();
      
      // OPTION 3: Uncomment for cleanup-only mode (marks all as processed without trying to send)
      // _initializeWithCleanupOnly();

      return repositories;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.convertException(error, stackTrace);
      debugPrint('App initialization failed: $appError');
      rethrow;
    }
  }

  /// Initialize Firebase (ADD THIS METHOD)
  static Future<void> _initializeFirebase() async {
    try {
      debugPrint('[AppInitializer] Initializing Firebase...');
      await Firebase.initializeApp();
      debugPrint('[AppInitializer] ✅ Firebase initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('[AppInitializer] ❌ Firebase initialization failed: $error');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - app can work without Firebase
    }
  }

  /// Initialize connectivity service
  static Future<void> _initializeConnectivityService() async {
    try {
      debugPrint('[AppInitializer] Initializing connectivity service...');
      await ConnectivityService.instance.initialize();
      debugPrint('[AppInitializer] ✅ Connectivity service initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('[AppInitializer] ❌ Connectivity service initialization failed: $error');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - app can work without connectivity monitoring
    }
  }

  /// Set up global error handling
  static Future<void> _setupErrorHandling() async {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        // In production, you might want to send errors to a logging service
        debugPrint('Flutter Error: ${details.exception}');
        debugPrint('Stack Trace: ${details.stack}');
      }
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Platform Error: $error');
        debugPrint('Stack Trace: $stack');
      } else {
        // In production, you might want to send errors to a logging service
        debugPrint('Platform Error: $error');
      }
      return true;
    };
  }

  /// Set up BLoC observer for state monitoring
  static void _setupBlocObserver() {
    Bloc.observer = AppBlocObserver();
  }

  /// Initialize Supabase connection
  static Future<void> _initializeSupabase() async {
    try {
      await SupabaseClientWrapper.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      debugPrint('[AppInitializer] Supabase initialized successfully');
    } catch (error, stackTrace) {
      throw DatabaseException(
        'Failed to initialize Supabase connection',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Initialize all repositories
  static Future<AppRepositories> _initializeRepositories() async {
    try {
      final reportRepository = ReportRepository();
      final schoolRepository = SchoolRepository();
      final authRepository = AuthRepository();

      debugPrint('[AppInitializer] Repositories initialized successfully');

      return AppRepositories(
        reportRepository: reportRepository,
        schoolRepository: schoolRepository,
        authRepository: authRepository,
      );
    } catch (error, stackTrace) {
      throw GenericException(
        'Failed to initialize repositories',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set up database tables and configuration
  static Future<void> _setupDatabase(AuthRepository authRepository) async {
    try {
      debugPrint('[AppInitializer] Setting up database tables...');
      await authRepository.ensureTablesExist();
      debugPrint('[AppInitializer] Database setup completed successfully');
    } catch (error, stackTrace) {
      debugPrint('[AppInitializer] Database setup failed: $error');
      // Don't throw here - app can still function with existing tables
      // Just log the error for debugging
    }
  }

  /// Initialize notification service
  static Future<void> _initializeNotificationService() async {
    try {
      debugPrint('[AppInitializer] Initializing notification service...');

      // Minimal delay for auth to be fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      await NotificationService.instance.init();

      debugPrint(
          '[AppInitializer] Notification service initialized successfully');
    } catch (error, stackTrace) {
      debugPrint(
          '[AppInitializer] Failed to initialize notification service: $error');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - app can work without notifications
    }
  }

  /// Initialize FCM service (UPDATED METHOD)
  static Future<void> _initializeFCMService() async {
    try {
      debugPrint('[AppInitializer] Initializing FCM service...');

      // Check if Firebase is already initialized
      try {
        Firebase.app();
        debugPrint(
            '[AppInitializer] Firebase app found, proceeding with FCM...');
      } catch (e) {
        debugPrint(
            '[AppInitializer] Firebase not initialized, initializing now...');
        await Firebase.initializeApp();
      }

      await FCMService.instance.initialize();
      debugPrint('[AppInitializer] ✅ FCM service initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('[AppInitializer] ❌ Failed to initialize FCM service: $error');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - app can work without push notifications
    }
  }

  /// Validate that all critical services are working
  static Future<bool> validateInitialization() async {
    try {
      // Test Supabase connection
      final client = SupabaseClientWrapper.client;
      if (client.auth.currentUser != null) {
        debugPrint('[AppInitializer] Validation: User is authenticated');
      } else {
        debugPrint('[AppInitializer] Validation: No authenticated user');
      }

      // Test Firebase connection
      try {
        final app = Firebase.app();
        debugPrint(
            '[AppInitializer] Validation: Firebase app found - ${app.name}');
      } catch (e) {
        debugPrint('[AppInitializer] Validation: Firebase not initialized');
      }

      debugPrint('[AppInitializer] App validation completed successfully');
      return true;
    } catch (error) {
      debugPrint('[AppInitializer] App validation failed: $error');
      return false;
    }
  }

  /// Initialize background services asynchronously to avoid blocking startup
  static void _initializeBackgroundServices() {
    // Initialize notification services in the background with staggered delays
    Timer(const Duration(seconds: 1), () async {
      await _initializeNotificationService();
    });
    
    Timer(const Duration(seconds: 2), () async {
      await _initializeFCMService();
    });
    
    // Process pending notifications after services are initialized
    Timer(const Duration(seconds: 4), () async {
      await _processPendingNotifications();
    });
  }

  /// OPTION 2: Initialize services only, no notification processing
  static void _initializeServicesOnly() {
    Timer(const Duration(seconds: 1), () async {
      await _initializeNotificationService();
    });
    
    Timer(const Duration(seconds: 2), () async {
      await _initializeFCMService();
    });
    
    debugPrint('[AppInitializer] 🚫 Notification processing disabled - no queue processing');
  }

  /// OPTION 3: Initialize services and cleanup old notifications without sending
  static void _initializeWithCleanupOnly() {
    Timer(const Duration(seconds: 1), () async {
      await _initializeNotificationService();
    });
    
    Timer(const Duration(seconds: 2), () async {
      await _initializeFCMService();
    });
    
    // Just mark old notifications as processed without trying to send them
    Timer(const Duration(seconds: 4), () async {
      await _cleanupOldNotifications();
    });
  }

  /// Process pending notifications asynchronously without blocking startup
  static void _processPendingNotificationsAsync() {
    // Run notification processing in the background after a delay
    Timer(const Duration(seconds: 3), () async {
      await _processPendingNotifications();
    });
  }

  /// Process pending notifications in the queue (optimized version)
  static Future<void> _processPendingNotifications() async {
    try {
      debugPrint('[AppInitializer] Processing pending notifications...');

      final client = SupabaseClientWrapper.client;

      // Check if user is authenticated first
      if (client.auth.currentUser == null) {
        debugPrint('[AppInitializer] No authenticated user - skipping notification processing');
        return;
      }

      // Get unprocessed notifications with timeout
      final queueResponse = await client
          .from('notification_queue')
          .select('*')
          .eq('processed', false)
          .limit(10) // Process more notifications in background
          .timeout(const Duration(seconds: 5));

      final notifications = queueResponse as List<dynamic>;

      if (notifications.isEmpty) {
        debugPrint('[AppInitializer] No pending notifications to process');
        return;
      }

      debugPrint(
          '[AppInitializer] Found ${notifications.length} pending notifications');

      // Process notifications in batches with error handling
      for (final notification in notifications) {
        try {
          // Add timeout to prevent hanging
          final response = await client.functions.invoke(
            'send_notification',
            body: {
              'user_id': notification['user_id'],
              'title': notification['title'],
              'body': notification['body'],
              'data': notification['data'],
              'priority': notification['data']?['priority'] ?? 'normal',
              'school_name': notification['data']?['school_name'] ?? 'Unknown School',
            },
            headers: {
              'Authorization':
                  'Bearer ${client.auth.currentSession?.accessToken}',
            },
          ).timeout(const Duration(seconds: 10));

          if (response.status == 200) {
            await client
                .from('notification_queue')
                .update({'processed': true})
                .eq('id', notification['id'])
                .timeout(const Duration(seconds: 5));

            debugPrint(
                '[AppInitializer] ✅ Processed notification ${notification['id']}');
          } else if (response.status == 404) {
            // Mark as processed if FCM token not found (no point in retrying)
            await client
                .from('notification_queue')
                .update({'processed': true})
                .eq('id', notification['id'])
                .timeout(const Duration(seconds: 5));

            debugPrint(
                '[AppInitializer] ⚠️ Marked notification ${notification['id']} as processed (FCM token not found)');
          }
        } catch (error) {
          debugPrint(
              '[AppInitializer] Error processing notification ${notification['id']}: $error');
          
          // If it's a FCM token error, mark as processed to avoid infinite retries
          if (error.toString().contains('No FCM tokens found')) {
            try {
              await client
                  .from('notification_queue')
                  .update({'processed': true})
                  .eq('id', notification['id'])
                  .timeout(const Duration(seconds: 5));
              
              debugPrint(
                  '[AppInitializer] ⚠️ Marked notification ${notification['id']} as processed (FCM token error)');
            } catch (markError) {
              debugPrint('[AppInitializer] Failed to mark notification as processed: $markError');
            }
          }
          
          // Continue processing other notifications
          continue;
        }
      }

      debugPrint(
          '[AppInitializer] ✅ Finished processing pending notifications');
    } catch (error) {
      debugPrint(
          '[AppInitializer] ❌ Error processing pending notifications: $error');
      // Don't rethrow - this shouldn't block app functionality
    }
  }

  /// Clean up old notifications without attempting to send them
  static Future<void> _cleanupOldNotifications() async {
    try {
      debugPrint('[AppInitializer] 🧹 Cleaning up old notifications...');

      final client = SupabaseClientWrapper.client;

      // Check if user is authenticated first
      if (client.auth.currentUser == null) {
        debugPrint('[AppInitializer] No authenticated user - skipping cleanup');
        return;
      }

      // Mark all unprocessed notifications as processed (cleanup mode)
      final result = await client
          .from('notification_queue')
          .update({'processed': true})
          .eq('processed', false)
          .timeout(const Duration(seconds: 10));

      debugPrint('[AppInitializer] ✅ Cleaned up old notifications');
    } catch (error) {
      debugPrint('[AppInitializer] ❌ Error cleaning up notifications: $error');
    }
  }
}
