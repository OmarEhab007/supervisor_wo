import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/core/services/connectivity_service.dart';
import 'package:supervisor_wo/core/utils/app_exception.dart' as app_exceptions;

/// Base repository class providing common database operations
abstract class BaseRepository {
  /// Access to the Supabase client
  SupabaseClient get client => SupabaseClientWrapper.client;
  
  /// Access to the connectivity service
  ConnectivityService get connectivityService => ConnectivityService.instance;

  /// Safely executes a database operation with error handling
  Future<T> safeDbCall<T>(
    Future<T> Function() dbCall, {
    T? fallback,
    String? context,
  }) async {
    try {
      return await dbCall();
    } catch (error, stackTrace) {
      final appError =
          app_exceptions.ErrorHandler.convertException(error, stackTrace);

      // If fallback is provided, use it instead of throwing
      if (fallback != null) {
        _logError(context, appError);
        return fallback;
      }

      // Add context if provided
      if (context != null) {
        throw app_exceptions.DatabaseException(
          '$context: ${appError.message}',
          code: appError.code,
          originalError: appError.originalError,
          stackTrace: stackTrace,
        );
      }

      throw appError;
    }
  }

  /// Network-aware database call with connectivity checking
  Future<T> safeNetworkDbCall<T>(
    Future<T> Function() dbCall, {
    T? fallback,
    String? context,
    bool checkConnectivity = true,
  }) async {
    // Check connectivity first if requested
    if (checkConnectivity && !connectivityService.isConnected) {
      if (fallback != null) {
        _logError(context, app_exceptions.NetworkException.noInternet(
          context: context ?? 'Database operation',
        ));
        return fallback;
      }
      throw app_exceptions.NetworkException.noInternet(
        context: context ?? 'Database operation',
      );
    }

    try {
      return await dbCall();
    } catch (error, stackTrace) {
      final appError =
          app_exceptions.ErrorHandler.convertException(error, stackTrace);

      // If it's a network error and we have fallback, use it
      if (appError is app_exceptions.NetworkException && fallback != null) {
        _logError(context, appError);
        return fallback;
      }

      // Add context if provided
      if (context != null) {
        if (appError is app_exceptions.NetworkException) {
          throw app_exceptions.NetworkException(
            '$context: ${appError.message}',
            code: appError.code,
            originalError: appError.originalError,
            stackTrace: stackTrace,
            errorType: appError.errorType,
            isRetryable: appError.isRetryable,
          );
        } else {
          throw app_exceptions.DatabaseException(
            '$context: ${appError.message}',
            code: appError.code,
            originalError: appError.originalError,
            stackTrace: stackTrace,
          );
        }
      }

      throw appError;
    }
  }

  /// Database call with retry mechanism for network failures
  Future<T> safeDbCallWithRetry<T>(
    Future<T> Function() dbCall, {
    T? fallback,
    String? context,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    late dynamic lastError;

    while (attempt < maxRetries) {
      try {
        // Check connectivity before each attempt
        if (!connectivityService.isConnected) {
          await Future.delayed(retryDelay);
          // Wait for connectivity to be restored or timeout
          await _waitForConnectivity(timeout: retryDelay);
        }

        return await dbCall();
      } catch (error, stackTrace) {
        lastError = error;
        final appError =
            app_exceptions.ErrorHandler.convertException(error, stackTrace);

        // Only retry for retryable network errors
        if (appError is app_exceptions.NetworkException && appError.isRetryable) {
          attempt++;
          if (attempt < maxRetries) {
            _logError(context, app_exceptions.NetworkException(
              'Attempt $attempt failed, retrying... ${appError.message}',
              originalError: error,
            ));
            await Future.delayed(retryDelay * attempt); // Exponential backoff
            continue;
          }
        }

        // If not retryable or max retries reached, handle the error
        if (fallback != null) {
          _logError(context, appError);
          return fallback;
        }

        if (context != null) {
          throw app_exceptions.DatabaseException(
            '$context: ${appError.message} (after $attempt attempts)',
            code: appError.code,
            originalError: appError.originalError,
            stackTrace: stackTrace,
          );
        }

        throw appError;
      }
    }

    // This should never be reached, but just in case
    throw app_exceptions.NetworkException(
      'Max retries ($maxRetries) exceeded',
      originalError: lastError,
    );
  }

  /// Wait for connectivity to be restored
  Future<void> _waitForConnectivity({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (connectivityService.isConnected) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = connectivityService.connectivityStream.listen((status) {
      if (status == ConnectivityStatus.connected) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Set up timeout
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(); // Complete anyway after timeout
      }
    });

    return completer.future;
  }

  /// Safely executes a database operation with mock data fallback
  Future<T> safeDbCallWithMockFallback<T>(
    Future<T> Function() dbCall,
    T Function() mockDataProvider, {
    String? context,
    Duration mockDelay = const Duration(milliseconds: 800),
  }) async {
    try {
      return await dbCall();
    } catch (error, stackTrace) {
      final appError =
          app_exceptions.ErrorHandler.convertException(error, stackTrace);
      _logError(context, appError);

      // Add delay to simulate network call
      await Future.delayed(mockDelay);
      return mockDataProvider();
    }
  }

  /// Get current authenticated user ID
  String? get currentUserId => client.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Ensure user is authenticated, throw exception if not
  String requireAuthenticatedUser() {
    final userId = currentUserId;
    if (userId == null) {
      throw app_exceptions.AuthException('User not authenticated');
    }
    return userId;
  }

  /// Execute a query with user filtering
  Future<T> executeUserQuery<T>(
    Future<T> Function(String userId) query, {
    String? context,
  }) async {
    final userId = requireAuthenticatedUser();
    return safeDbCall(
      () => query(userId),
      context: context ?? 'User query execution',
    );
  }

  /// Build a select query for a table
  PostgrestFilterBuilder selectFrom(String table, {String columns = '*'}) {
    return client.from(table).select(columns);
  }

  /// Build an insert query for a table
  PostgrestFilterBuilder insertInto(String table, Map<String, dynamic> data) {
    return client.from(table).insert(data);
  }

  /// Build an update query for a table
  PostgrestFilterBuilder updateTable(String table, Map<String, dynamic> data) {
    return client.from(table).update(data);
  }

  /// Build a delete query for a table
  PostgrestFilterBuilder deleteFrom(String table) {
    return client.from(table).delete();
  }

  /// Check if a table exists by attempting to query it
  Future<bool> tableExists(String tableName) async {
    try {
      await selectFrom(tableName).limit(1);
      return true;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('does not exist') ||
          errorString.contains('table') && errorString.contains('not found')) {
        return false;
      }
      rethrow;
    }
  }

  /// Try multiple table names to find user profile
  Future<Map<String, dynamic>?> findUserProfileFromTables(
    String userId,
    List<String> tableNames,
  ) async {
    for (final tableName in tableNames) {
      try {
        final response = await selectFrom(tableName).eq('id', userId).single();
        return response;
      } catch (e) {
        // Continue to next table if this one fails
        continue;
      }
    }
    return null;
  }

  /// Log errors for debugging
  void _logError(String? context, app_exceptions.AppException error) {
    final prefix = context != null ? '[$context]' : '[Repository]';
    print('$prefix Error: ${error.message}');
    if (error.originalError != null) {
      print('$prefix Original error: ${error.originalError}');
    }
  }

  /// Batch operation helper
  Future<List<T>> batchOperation<T>(
    List<Future<T> Function()> operations, {
    bool continueOnError = false,
  }) async {
    final results = <T>[];

    for (final operation in operations) {
      try {
        final result = await operation();
        results.add(result);
      } catch (e) {
        if (!continueOnError) {
          rethrow;
        }
        // Skip failed operations if continueOnError is true
      }
    }

    return results;
  }

  /// Pagination helper
  Future<List<T>> getPaginatedResults<T>(
    String table,
    T Function(Map<String, dynamic>) mapper, {
    int page = 0,
    int pageSize = 20,
    String orderBy = 'created_at',
    bool ascending = false,
    Map<String, dynamic>? filters,
  }) async {
    return safeDbCall(() async {
      var query = selectFrom(table);

      // Apply filters if provided
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Apply ordering and pagination
      final response = await query
          .order(orderBy, ascending: ascending)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return response.map<T>((data) => mapper(data)).toList();
    });
  }
}
