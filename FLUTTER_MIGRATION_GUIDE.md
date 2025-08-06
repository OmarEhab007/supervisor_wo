# Flutter App Migration Guide

## Overview

This document provides step-by-step instructions for migrating the Flutter mobile application from Supabase to the custom backend. The migration involves updating dependencies, refactoring repository layers, implementing new HTTP clients, and updating authentication flows.

## Prerequisites

- Flutter SDK 3.6.2 or later
- Custom backend API running and accessible
- Updated API endpoints and authentication tokens

## Migration Steps

### 1. Update Dependencies

Update `pubspec.yaml` to replace Supabase dependencies with HTTP client dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Remove Supabase dependency
  # supabase_flutter: ^2.9.0

  # Add HTTP client dependencies
  dio: ^5.4.0
  dio_certificate_pinning: ^4.1.0
  dio_cache_interceptor: ^3.4.4
  dio_cache_interceptor_hive_store: ^3.2.2

  # Keep existing dependencies
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^17.0.0
  shared_preferences: ^2.2.2
  equatable: ^2.0.7
  flutter_bloc: ^9.1.1
  connectivity_plus: ^6.0.5
  image_picker: ^1.1.2
  permission_handler: ^11.3.0
  device_info_plus: ^9.1.2
  url_launcher: ^6.2.5
  package_info_plus: ^8.0.2
  go_router: ^15.1.2
  intl: ^0.20.2
  photo_view: ^0.15.0
  google_fonts: ^6.2.1
  skeletonizer: ^1.4.3
  fl_chart: ^0.66.2
  flutter_launcher_icons: ^0.14.3
  uuid: ^4.5.1
  upgrader: ^11.4.0

  # Add secure storage for tokens
  flutter_secure_storage: ^9.0.0

  # Add JSON annotation for model generation
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mockito: ^5.4.5
  build_runner: ^2.4.15
  json_serializable: ^6.7.1
```

### 2. Create HTTP Service Layer

Create a new HTTP service to replace Supabase client:

```dart
// lib/core/services/http_service.dart
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:supervisor_wo/core/services/token_storage.dart';
import 'package:supervisor_wo/core/utils/app_exception.dart';

class HttpService {
  static HttpService? _instance;
  late final Dio _dio;
  late final CacheStore _cacheStore;

  HttpService._() {
    _dio = Dio();
    _setupInterceptors();
  }

  static HttpService get instance {
    _instance ??= HttpService._();
    return _instance!;
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    // Request/Response Logging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ));
    }

    // Authentication Interceptor
    _dio.interceptors.add(AuthInterceptor());

    // Cache Interceptor
    _setupCacheInterceptor();

    // Error Handling Interceptor
    _dio.interceptors.add(ErrorInterceptor());
  }

  void _setupCacheInterceptor() {
    _cacheStore = HiveCacheStore(null);
    
    final cacheOptions = CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403, 500],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );

    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  }

  // GET Request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT Request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException('Connection timeout. Please check your internet connection.');
        case DioExceptionType.badResponse:
          return _handleBadResponse(error);
        case DioExceptionType.cancel:
          return NetworkException('Request was cancelled');
        case DioExceptionType.unknown:
          return NetworkException('Network error occurred. Please try again.');
        default:
          return GenericException('An unexpected error occurred');
      }
    }
    return GenericException('An unexpected error occurred');
  }

  Exception _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (statusCode) {
      case 400:
        return ValidationException(
          data?['error']?['message'] ?? 'Invalid request data',
        );
      case 401:
        return AuthException('Authentication failed. Please login again.');
      case 403:
        return AuthException('You do not have permission to perform this action.');
      case 404:
        return NetworkException('The requested resource was not found.');
      case 422:
        return ValidationException(
          data?['error']?['message'] ?? 'Validation failed',
        );
      case 429:
        return NetworkException('Too many requests. Please try again later.');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException('Server error. Please try again later.');
      default:
        return NetworkException(
          data?['error']?['message'] ?? 'Network error occurred',
        );
    }
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  void clearCache() {
    _cacheStore.clean();
  }
}
```

### 3. Create Authentication Interceptor

```dart
// lib/core/services/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:supervisor_wo/core/services/token_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/register endpoints
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request
        final response = await _retryRequest(err.requestOptions);
        handler.resolve(response);
        return;
      } else {
        // Clear tokens and redirect to login
        await TokenStorage.clearTokens();
        // Navigate to login screen
        // You might want to use a navigation service here
      }
    }
    handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') || 
           path.contains('/auth/register') || 
           path.contains('/auth/refresh');
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final dio = Dio();
      final response = await dio.post(
        '${HttpService.instance.dio.options.baseUrl}/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await TokenStorage.saveAccessToken(data['access_token']);
        return true;
      }
    } catch (e) {
      // Refresh failed
    }
    return false;
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      requestOptions.headers['Authorization'] = 'Bearer $token';
    }
    
    return HttpService.instance.dio.fetch(requestOptions);
  }
}
```

### 4. Create Token Storage Service

```dart
// lib/core/services/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      if (userId != null) _storage.write(key: _userIdKey, value: userId),
    ]);
  }

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
    ]);
  }
}
```

### 5. Update Configuration

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.supervisor-wo.com',
  );

  static const String stagingUrl = 'https://staging-api.supervisor-wo.com';
  static const String developmentUrl = 'http://localhost:3000';

  // API Endpoints
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authRefresh = '/api/auth/refresh';
  static const String authProfile = '/api/auth/profile';
  
  static const String schools = '/api/schools';
  static const String reports = '/api/reports';
  static const String maintenanceReports = '/api/maintenance-reports';
  static const String damageCounts = '/api/damage-counts';
  static const String schoolAchievements = '/api/school-achievements';
  static const String uploadPhoto = '/api/upload/photo';
  static const String uploadMultiplePhotos = '/api/upload/multiple-photos';
  static const String notifications = '/api/notifications';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // File upload limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
}
```

### 6. Update Authentication Repository

```dart
// lib/core/repositories/auth_repository.dart
import 'package:supervisor_wo/core/config/api_config.dart';
import 'package:supervisor_wo/core/services/http_service.dart';
import 'package:supervisor_wo/core/services/token_storage.dart';
import 'package:supervisor_wo/models/user_profile.dart';
import 'package:supervisor_wo/models/auth_response.dart';

class AuthRepository {
  final HttpService _httpService = HttpService.instance;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _httpService.post(
      ApiConfig.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data['data']);
    
    // Save tokens
    await TokenStorage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      userId: authResponse.user.id,
    );

    return authResponse;
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String phone,
    String? plateNumbers,
    String? plateEnglishLetters,
    String? plateArabicLetters,
    String? iqamaId,
    String? workId,
  }) async {
    final response = await _httpService.post(
      ApiConfig.authRegister,
      data: {
        'email': email,
        'password': password,
        'username': username,
        'phone': phone,
        'plate_numbers': plateNumbers,
        'plate_english_letters': plateEnglishLetters,
        'plate_arabic_letters': plateArabicLetters,
        'iqama_id': iqamaId,
        'work_id': workId,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data['data']);
    
    // Save tokens
    await TokenStorage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      userId: authResponse.user.id,
    );

    return authResponse;
  }

  Future<UserProfile> getCurrentProfile() async {
    final response = await _httpService.get(ApiConfig.authProfile);
    return UserProfile.fromJson(response.data['data']);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _httpService.put(
      ApiConfig.authProfile,
      data: profileData,
    );
    return UserProfile.fromJson(response.data['data']);
  }

  Future<void> signOut() async {
    // Clear local tokens
    await TokenStorage.clearTokens();
    
    // Clear HTTP cache
    HttpService.instance.clearCache();
  }

  Future<bool> isAuthenticated() async {
    return await TokenStorage.hasValidTokens();
  }

  // Remove Supabase-specific methods and replace with HTTP calls
  Future<void> ensureTablesExist() async {
    // This is no longer needed as the backend handles database setup
    // Remove this method or make it a no-op
  }
}
```

### 7. Update Report Repository

```dart
// lib/core/repositories/report_repository.dart
import 'package:supervisor_wo/core/config/api_config.dart';
import 'package:supervisor_wo/core/services/http_service.dart';
import 'package:supervisor_wo/models/report_model.dart';
import 'package:supervisor_wo/models/maintenance_report_model.dart';

class ReportRepository {
  final HttpService _httpService = HttpService.instance;

  Future<List<Report>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? priority,
    String? schoolId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (priority != null) 'priority': priority,
      if (schoolId != null) 'school_id': schoolId,
      if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo.toIso8601String(),
    };

    final response = await _httpService.get(
      ApiConfig.reports,
      queryParameters: queryParams,
    );

    final List<dynamic> reportsList = response.data['data']['reports'];
    return reportsList.map((json) => Report.fromMap(json)).toList();
  }

  Future<Report> getReport(String reportId) async {
    final response = await _httpService.get('${ApiConfig.reports}/$reportId');
    return Report.fromMap(response.data['data']);
  }

  Future<Report> createReport({
    required String schoolId,
    required String description,
    required String type,
    required String priority,
    required List<String> images,
    required DateTime scheduledDate,
  }) async {
    final response = await _httpService.post(
      ApiConfig.reports,
      data: {
        'school_id': schoolId,
        'description': description,
        'type': type,
        'priority': priority,
        'images': images,
        'scheduled_date': scheduledDate.toIso8601String(),
      },
    );

    return Report.fromMap(response.data['data']);
  }

  Future<Report> updateReport(String reportId, Map<String, dynamic> updates) async {
    final response = await _httpService.put(
      '${ApiConfig.reports}/$reportId',
      data: updates,
    );

    return Report.fromMap(response.data['data']);
  }

  Future<Report> completeReport({
    required String reportId,
    required String completionNote,
    required List<String> completionPhotos,
  }) async {
    final response = await _httpService.post(
      '${ApiConfig.reports}/$reportId/complete',
      data: {
        'completion_note': completionNote,
        'completion_photos': completionPhotos,
      },
    );

    return Report.fromMap(response.data['data']);
  }

  // Maintenance Reports
  Future<List<MaintenanceReport>> getMaintenanceReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? schoolId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (schoolId != null) 'school_id': schoolId,
    };

    final response = await _httpService.get(
      ApiConfig.maintenanceReports,
      queryParameters: queryParams,
    );

    final List<dynamic> reportsList = response.data['data']['maintenance_reports'];
    return reportsList.map((json) => MaintenanceReport.fromMap(json)).toList();
  }

  Future<MaintenanceReport> createMaintenanceReport({
    required String schoolId,
    required Map<String, dynamic> reportData,
    required List<String> photos,
    String status = 'draft',
  }) async {
    final response = await _httpService.post(
      ApiConfig.maintenanceReports,
      data: {
        'school_id': schoolId,
        'report_data': reportData,
        'photos': photos,
        'status': status,
      },
    );

    return MaintenanceReport.fromMap(response.data['data']);
  }

  Future<MaintenanceReport> completeMaintenanceReport({
    required String reportId,
    required String completionNote,
    required List<String> completionPhotos,
  }) async {
    final response = await _httpService.post(
      '${ApiConfig.maintenanceReports}/$reportId/complete',
      data: {
        'completion_note': completionNote,
        'completion_photos': completionPhotos,
      },
    );

    return MaintenanceReport.fromMap(response.data['data']);
  }
}
```

### 8. Create File Upload Service

```dart
// lib/core/services/file_upload_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:supervisor_wo/core/config/api_config.dart';
import 'package:supervisor_wo/core/services/http_service.dart';
import 'package:supervisor_wo/models/upload_response.dart';

class FileUploadService {
  final HttpService _httpService = HttpService.instance;

  Future<UploadResponse> uploadPhoto(File photo) async {
    // Validate file size
    final fileSize = await photo.length();
    if (fileSize > ApiConfig.maxFileSize) {
      throw Exception('File size exceeds maximum limit of ${ApiConfig.maxFileSize / (1024 * 1024)}MB');
    }

    final fileName = path.basename(photo.path);
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: fileName,
      ),
    });

    final response = await _httpService.post(
      ApiConfig.uploadPhoto,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    return UploadResponse.fromJson(response.data['data']);
  }

  Future<List<UploadResponse>> uploadMultiplePhotos(List<File> photos) async {
    final List<MultipartFile> photoFiles = [];
    
    for (final photo in photos) {
      // Validate each file
      final fileSize = await photo.length();
      if (fileSize > ApiConfig.maxFileSize) {
        throw Exception('File ${path.basename(photo.path)} exceeds maximum size limit');
      }

      photoFiles.add(
        await MultipartFile.fromFile(
          photo.path,
          filename: path.basename(photo.path),
        ),
      );
    }

    final formData = FormData.fromMap({
      'photos': photoFiles,
    });

    final response = await _httpService.post(
      ApiConfig.uploadMultiplePhotos,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    final List<dynamic> uploadedFiles = response.data['data']['uploaded_files'];
    return uploadedFiles.map((json) => UploadResponse.fromJson(json)).toList();
  }

  Future<void> deleteFile(String fileId) async {
    await _httpService.delete('/api/files/$fileId');
  }
}
```

### 9. Update App Initialization

```dart
// lib/core/services/app_initializer.dart
import 'package:supervisor_wo/core/config/api_config.dart';
import 'package:supervisor_wo/core/services/http_service.dart';
import 'package:supervisor_wo/core/services/token_storage.dart';

class AppInitializer {
  static Future<AppRepositories> initializeApp() async {
    try {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Set up error handling
      await _setupErrorHandling();

      // Set up BLoC observer
      _setupBlocObserver();

      // Initialize Firebase FIRST
      await _initializeFirebase();

      // Initialize connectivity service
      await _initializeConnectivityService();

      // Initialize HTTP service
      await _initializeHttpService();

      // Initialize repositories
      final repositories = await _initializeRepositories();

      // Initialize background services
      _initializeServicesOnly();

      return repositories;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.convertException(error, stackTrace);
      debugPrint('App initialization failed: $appError');
      rethrow;
    }
  }

  static Future<void> _initializeHttpService() async {
    try {
      debugPrint('[AppInitializer] Initializing HTTP service...');
      
      // Set base URL for HTTP service
      HttpService.instance.updateBaseUrl(ApiConfig.baseUrl);
      
      debugPrint('[AppInitializer] ✅ HTTP service initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('[AppInitializer] ❌ HTTP service initialization failed: $error');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Remove Supabase initialization method
  // static Future<void> _initializeSupabase() async { ... }

  static Future<AppRepositories> _initializeRepositories() async {
    try {
      final reportRepository = ReportRepository();
      final schoolRepository = SchoolRepository();
      final authRepository = AuthRepository();
      final maintenanceCountRepository = MaintenanceCountRepository();
      final damageCountRepository = DamageCountRepository();

      debugPrint('[AppInitializer] Repositories initialized successfully');

      return AppRepositories(
        reportRepository: reportRepository,
        schoolRepository: schoolRepository,
        authRepository: authRepository,
        maintenanceCountRepository: maintenanceCountRepository,
        damageCountRepository: damageCountRepository,
      );
    } catch (error, stackTrace) {
      throw GenericException(
        'Failed to initialize repositories',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  // Remove database setup method as it's handled by the backend
  // static Future<void> _setupDatabase(AuthRepository authRepository) async { ... }

  // Keep existing Firebase and notification initialization methods
  // ...
}
```

### 10. Update Models with JSON Serialization

Add JSON serialization to your models:

```dart
// lib/models/auth_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:supervisor_wo/models/user_profile.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final UserProfile user;
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
```

```dart
// lib/models/upload_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'upload_response.g.dart';

@JsonSerializable()
class UploadResponse {
  @JsonKey(name: 'file_id')
  final String fileId;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'original_name')
  final String originalName;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'mime_type')
  final String? mimeType;

  UploadResponse({
    required this.fileId,
    required this.fileUrl,
    required this.originalName,
    this.fileSize,
    this.mimeType,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadResponseToJson(this);
}
```

### 11. Update Error Handling

```dart
// lib/core/utils/app_exception.dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code})
      : super(message, code: code);
}

class AuthException extends AppException {
  const AuthException(String message, {String? code})
      : super(message, code: code);
}

class ValidationException extends AppException {
  const ValidationException(String message, {String? code})
      : super(message, code: code);
}

class ServerException extends AppException {
  const ServerException(String message, {String? code})
      : super(message, code: code);
}

class GenericException extends AppException {
  const GenericException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class ErrorHandler {
  static AppException convertException(dynamic error, StackTrace? stackTrace) {
    if (error is AppException) {
      return error;
    }
    
    return GenericException(
      'An unexpected error occurred',
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
```

### 12. Update Environment Configuration

Create environment-specific configurations:

```dart
// lib/core/config/environment.dart
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment get current {
    const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    switch (env) {
      case 'staging':
        return Environment.staging;
      case 'production':
        return Environment.production;
      default:
        return Environment.development;
    }
  }

  static String get baseUrl {
    switch (current) {
      case Environment.development:
        return ApiConfig.developmentUrl;
      case Environment.staging:
        return ApiConfig.stagingUrl;
      case Environment.production:
        return ApiConfig.baseUrl;
    }
  }

  static bool get isDebug => current == Environment.development;
  static bool get isProduction => current == Environment.production;
}
```

### 13. Testing

Create comprehensive tests for the new HTTP service:

```dart
// test/core/services/http_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:supervisor_wo/core/services/http_service.dart';

@GenerateMocks([Dio])
void main() {
  group('HttpService', () {
    late HttpService httpService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      httpService = HttpService.instance;
    });

    test('should make successful GET request', () async {
      // Arrange
      const testData = {'message': 'success'};
      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          data: testData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Act
      final response = await httpService.get('/test');

      // Assert
      expect(response.data, equals(testData));
      expect(response.statusCode, equals(200));
    });

    test('should handle network errors properly', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Act & Assert
      expect(
        () => httpService.get('/test'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

### 14. Build and Test

1. **Run code generation:**
   ```bash
   flutter packages pub run build_runner build
   ```

2. **Update imports:**
   Remove all Supabase imports and update with new service imports.

3. **Test the migration:**
   ```bash
   flutter test
   flutter run
   ```

4. **Verify functionality:**
   - Authentication flow
   - Data fetching and caching
   - File uploads
   - Push notifications
   - Offline functionality

### 15. Deployment Considerations

1. **Update build configurations:**
   - Add environment variables for different API URLs
   - Update CI/CD pipelines
   - Configure certificate pinning for production

2. **App store updates:**
   - Update app descriptions
   - Prepare release notes
   - Plan staged rollout

3. **Monitoring:**
   - Set up crash reporting
   - Monitor API performance
   - Track user adoption

## Migration Checklist

- [ ] Update dependencies in pubspec.yaml
- [ ] Create HTTP service layer
- [ ] Implement authentication interceptor
- [ ] Set up token storage
- [ ] Update all repository classes
- [ ] Create file upload service
- [ ] Update error handling
- [ ] Add JSON serialization to models
- [ ] Update app initialization
- [ ] Create environment configurations
- [ ] Write comprehensive tests
- [ ] Update documentation
- [ ] Test in development environment
- [ ] Deploy to staging
- [ ] Perform user acceptance testing
- [ ] Deploy to production
- [ ] Monitor for issues

## Troubleshooting

### Common Issues and Solutions

1. **Certificate pinning issues:**
   - Ensure certificates are properly configured
   - Test with staging environment first

2. **Token refresh problems:**
   - Verify refresh token endpoint
   - Check token expiration handling

3. **File upload failures:**
   - Check file size limits
   - Verify multipart form data format

4. **Cache issues:**
   - Clear app cache during testing
   - Verify cache invalidation logic

5. **Network connectivity:**
   - Test offline scenarios
   - Verify error handling for network failures

This migration guide provides a comprehensive approach to transitioning from Supabase to a custom backend while maintaining all existing functionality and improving performance and control.