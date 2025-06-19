import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Cache entry containing value and expiration time
class CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int accessCount;

  CacheEntry(
    this.value,
    this.expiresAt, {
    DateTime? createdAt,
    this.accessCount = 1,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a new entry with updated access count
  CacheEntry<T> withIncrementedAccess() {
    return CacheEntry<T>(
      value,
      expiresAt,
      createdAt: createdAt,
      accessCount: accessCount + 1,
    );
  }

  /// Check if the entry has expired
  bool isExpired([DateTime? now]) {
    now ??= DateTime.now();
    return now.isAfter(expiresAt);
  }

  /// Age of the cache entry
  Duration get age => DateTime.now().difference(createdAt);

  @override
  String toString() {
    return 'CacheEntry(value: $value, age: $age, accessCount: $accessCount, expired: ${isExpired()})';
  }
}

/// Cache configuration options
class CacheConfig {
  final Duration defaultTtl;
  final int maxEntries;
  final bool enableLogging;
  final Duration cleanupInterval;

  const CacheConfig({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxEntries = 100,
    this.enableLogging = false,
    this.cleanupInterval = const Duration(minutes: 10),
  });

  /// Configuration for production environment
  static const production = CacheConfig(
    defaultTtl: Duration(minutes: 10),
    maxEntries: 200,
    enableLogging: false,
    cleanupInterval: Duration(minutes: 15),
  );

  /// Configuration for development environment
  static const development = CacheConfig(
    defaultTtl: Duration(minutes: 2),
    maxEntries: 50,
    enableLogging: true,
    cleanupInterval: Duration(minutes: 5),
  );
}

/// In-memory cache service with TTL support
class CacheService {
  static CacheService? _instance;
  final Map<String, CacheEntry> _cache = <String, CacheEntry>{};
  final CacheConfig _config;

  // Statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  CacheService._(this._config);

  /// Get singleton instance
  static CacheService get instance {
    _instance ??= CacheService._(
      kDebugMode ? CacheConfig.development : CacheConfig.production,
    );
    return _instance!;
  }

  /// Initialize with custom configuration
  static void initialize(CacheConfig config) {
    _instance = CacheService._(config);
  }

  /// Get cached value or fetch and cache it
  Future<T> getCached<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    ttl ??= _config.defaultTtl;

    // Check if we should force refresh or if entry doesn't exist/is expired
    if (!forceRefresh) {
      final cached = _get<T>(key);
      if (cached != null) {
        _hits++;
        _log('Cache HIT for key: $key');
        return cached;
      }
    }

    // Cache miss or force refresh - fetch new data
    _misses++;
    _log('Cache MISS for key: $key, fetching...');

    try {
      final value = await fetcher();
      _set(key, value, ttl);
      _log('Cached new value for key: $key');
      return value;
    } catch (error) {
      _log('Error fetching data for key: $key - $error');
      rethrow;
    }
  }

  /// Get value from cache without fetching
  T? get<T>(String key) {
    return _get<T>(key);
  }

  /// Set value in cache
  void set<T>(String key, T value, [Duration? ttl]) {
    _set(key, value, ttl ?? _config.defaultTtl);
  }

  /// Remove specific key from cache
  void remove(String key) {
    final removed = _cache.remove(key);
    if (removed != null) {
      _log('Removed key from cache: $key');
    }
  }

  /// Clear all cache entries
  void clear() {
    final count = _cache.length;
    _cache.clear();
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _log('Cleared all cache entries: $count');
  }

  /// Clear expired entries
  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired(now))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _log('Cleared ${expiredKeys.length} expired entries');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? (_hits / totalRequests * 100) : 0.0;

    return {
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'hitRate': hitRate,
      'totalEntries': _cache.length,
      'maxEntries': _config.maxEntries,
      'memoryUsage': _calculateMemoryUsage(),
    };
  }

  /// Get cache entries info for debugging
  List<Map<String, dynamic>> getEntriesInfo() {
    return _cache.entries.map((entry) {
      final value = entry.value;
      return {
        'key': entry.key,
        'age': value.age.inSeconds,
        'accessCount': value.accessCount,
        'expired': value.isExpired(),
        'expiresIn': value.isExpired()
            ? 0
            : value.expiresAt.difference(DateTime.now()).inSeconds,
      };
    }).toList();
  }

  /// Internal get method
  T? _get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if expired
    if (entry.isExpired()) {
      _cache.remove(key);
      return null;
    }

    // Update access count
    _cache[key] = entry.withIncrementedAccess();
    return entry.value as T;
  }

  /// Internal set method
  void _set<T>(String key, T value, Duration ttl) {
    // Clean up if we're at capacity
    if (_cache.length >= _config.maxEntries) {
      _evictLeastRecentlyUsed();
    }

    final expiresAt = DateTime.now().add(ttl);
    _cache[key] = CacheEntry<T>(value, expiresAt);
  }

  /// Evict least recently used entries
  void _evictLeastRecentlyUsed() {
    if (_cache.isEmpty) return;

    // Find the entry with the oldest creation time and lowest access count
    String? keyToEvict;
    CacheEntry? oldestEntry;

    for (final entry in _cache.entries) {
      if (oldestEntry == null ||
          entry.value.createdAt.isBefore(oldestEntry.createdAt) ||
          (entry.value.createdAt == oldestEntry.createdAt &&
              entry.value.accessCount < oldestEntry.accessCount)) {
        oldestEntry = entry.value;
        keyToEvict = entry.key;
      }
    }

    if (keyToEvict != null) {
      _cache.remove(keyToEvict);
      _evictions++;
      _log('Evicted LRU entry: $keyToEvict');
    }
  }

  /// Calculate approximate memory usage
  String _calculateMemoryUsage() {
    // This is a rough estimation
    final entries = _cache.length;
    final approximateBytes = entries * 1024; // Rough estimate of 1KB per entry

    if (approximateBytes < 1024) {
      return '${approximateBytes}B';
    } else if (approximateBytes < 1024 * 1024) {
      return '${(approximateBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(approximateBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// Log cache operations
  void _log(String message) {
    if (_config.enableLogging && kDebugMode) {
      debugPrint('[CacheService] $message');
    }
  }

  @override
  String toString() {
    final stats = getStats();
    return 'CacheService(entries: ${stats['totalEntries']}, '
        'hitRate: ${stats['hitRate'].toStringAsFixed(1)}%, '
        'memory: ${stats['memoryUsage']})';
  }
}

/// Extension methods for easier cache usage
extension CacheServiceExtensions on CacheService {
  /// Cache user profile data
  Future<T> getCachedUserProfile<T>({
    required String userId,
    required Future<T> Function() fetcher,
  }) async {
    return getCached<T>(
      key: 'user_profile_$userId',
      fetcher: fetcher,
      ttl: const Duration(minutes: 15), // User profiles don't change often
    );
  }

  /// Cache reports data
  Future<List<T>> getCachedReports<T>({
    required String userId,
    required Future<List<T>> Function() fetcher,
    String? filter,
  }) async {
    final key =
        filter != null ? 'reports_${userId}_$filter' : 'reports_$userId';

    return getCached<List<T>>(
      key: key,
      fetcher: fetcher,
      ttl: const Duration(minutes: 5), // Reports change more frequently
    );
  }

  /// Cache schools data
  Future<List<T>> getCachedSchools<T>({
    required Future<List<T>> Function() fetcher,
  }) async {
    return getCached<List<T>>(
      key: 'schools_list',
      fetcher: fetcher,
      ttl: const Duration(hours: 1), // Schools don't change often
    );
  }

  /// Invalidate all user-related cache entries
  void invalidateUserCache(String userId) {
    final keysToRemove =
        _cache.keys.where((key) => key.contains(userId)).toList();

    for (final key in keysToRemove) {
      remove(key);
    }

    _log('Invalidated ${keysToRemove.length} entries for user: $userId');
  }

  /// Invalidate reports cache
  void invalidateReportsCache([String? userId]) {
    final pattern = userId != null ? 'reports_$userId' : 'reports_';
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith(pattern)).toList();

    for (final key in keysToRemove) {
      remove(key);
    }

    _log('Invalidated ${keysToRemove.length} report cache entries');
  }
}
