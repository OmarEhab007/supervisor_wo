# Network Connectivity Implementation Guide

This document outlines the comprehensive network connectivity solution implemented in the Supervisor Work Order app to handle network loss and connectivity issues gracefully.

## 📋 Overview

The implementation provides:
- **Real-time connectivity monitoring** using `connectivity_plus`
- **Intelligent error handling** with automatic retries
- **User-friendly UI feedback** for connectivity status
- **Offline-first repository pattern** with fallback data
- **Network-aware database operations** with timeout handling

## 🏗️ Architecture

### 1. Core Components

#### ConnectivityService (`lib/core/services/connectivity_service.dart`)
- Monitors device connectivity (WiFi, Mobile, None)
- Checks actual internet accessibility (not just network connection)
- Tests Supabase service availability
- Provides real-time connectivity stream

#### ConnectivityBloc (`lib/core/blocs/connectivity/`)
- Manages connectivity state throughout the app
- Handles connectivity events and state transitions  
- Provides user-friendly error messages
- Determines when network operations should be allowed

#### Enhanced BaseRepository (`lib/core/repositories/base_repository.dart`)
- `safeNetworkDbCall()` - Network-aware database operations
- `safeDbCallWithRetry()` - Automatic retry mechanism
- Connectivity checking before database calls
- Intelligent fallback strategies

#### UI Components (`lib/presentation/widgets/connectivity_banner.dart`)
- `ConnectivityBanner` - Full status banner with retry button
- `CompactConnectivityBanner` - Minimal status indicator
- `ConnectivitySnackbar` - Popup notifications for status changes

### 2. Network Exception Types

Enhanced `NetworkException` with specific error types:
- `NetworkErrorType.noInternet` - No internet connectivity
- `NetworkErrorType.timeout` - Request timeouts  
- `NetworkErrorType.serverError` - Server-side errors (500, 502, etc.)
- `NetworkErrorType.serviceUnavailable` - Service temporarily down
- `NetworkErrorType.connectionRefused` - Connection rejected
- `NetworkErrorType.hostUnreachable` - Network routing issues

## 🚀 Usage Guide

### 1. Setting Up the ConnectivityBloc

The ConnectivityBloc is already configured in `main.dart`:

```dart
BlocProvider<ConnectivityBloc>(
  create: (context) => ConnectivityBloc()
    ..add(const ConnectivityStarted()),
),
```

### 2. Adding Connectivity UI

#### Option A: Full Banner (Recommended for main screens)
```dart
import 'package:supervisor_wo/presentation/widgets/connectivity_banner.dart';

// In your screen's build method:
Column(
  children: [
    const ConnectivityBanner(), // Shows when disconnected
    // Your other widgets...
  ],
)
```

#### Option B: Compact Indicator
```dart
// Minimal 4px colored line at top of screen
const CompactConnectivityBanner()
```

#### Option C: Snackbar Notifications
```dart
// Listen to connectivity changes and show snackbars
BlocListener<ConnectivityBloc, ConnectivityState>(
  listener: (context, state) {
    ConnectivitySnackbar.show(context, state);
  },
  child: YourWidget(),
)
```

### 3. Network-Aware Repository Methods

#### Using safeNetworkDbCall (Recommended)
```dart
class MyRepository extends BaseRepository {
  Future<List<Data>> fetchData() async {
    return await safeNetworkDbCall(
      () async {
        // Your database operation here
        final response = await client.from('table').select();
        return response.map<Data>((json) => Data.fromJson(json)).toList();
      },
      fallback: _getMockData(), // Fallback data when offline
      context: 'Fetching data',  // Context for error messages
    );
  }
}
```

#### Using safeDbCallWithRetry (For critical operations)
```dart
Future<bool> updateImportantData(String id, Map<String, dynamic> data) async {
  return await safeDbCallWithRetry(
    () async {
      await client.from('table').update(data).eq('id', id);
      return true;
    },
    fallback: false,           // Return false if all retries fail
    context: 'Updating data',  // Context for error messages
    maxRetries: 3,            // Number of retry attempts
    retryDelay: Duration(seconds: 2), // Delay between retries
  );
}
```

### 4. Checking Connectivity Status

#### In Widgets
```dart
BlocBuilder<ConnectivityBloc, ConnectivityState>(
  builder: (context, state) {
    if (state.isConnected) {
      return OnlineWidget();
    } else {
      return OfflineWidget();
    }
  },
)
```

#### In Business Logic
```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  void _onDataRequested(DataRequested event, Emitter<MyState> emit) {
    final connectivityBloc = BlocProvider.of<ConnectivityBloc>(context);
    
    if (connectivityBloc.canPerformNetworkOperations) {
      // Proceed with network operation
    } else {
      emit(MyOfflineState());
    }
  }
}
```

### 5. Manual Connectivity Checks

#### Force Connectivity Check
```dart
context.read<ConnectivityBloc>().add(
  const ConnectivityCheckRequested(),
);
```

#### Retry Failed Operations
```dart
context.read<ConnectivityBloc>().add(
  const ConnectivityRetryRequested(),
);
```

#### Test Supabase Connectivity
```dart
context.read<ConnectivityBloc>().add(
  const ConnectivitySupabaseTestRequested(),
);
```

## 🎯 Best Practices

### 1. Repository Design
- ✅ **DO** extend `BaseRepository` for all data repositories
- ✅ **DO** use `safeNetworkDbCall()` for read operations
- ✅ **DO** use `safeDbCallWithRetry()` for critical write operations
- ✅ **DO** provide meaningful fallback data
- ❌ **DON'T** perform raw database calls without connectivity checking

### 2. UI Design
- ✅ **DO** show connectivity status to users
- ✅ **DO** provide retry buttons for failed operations
- ✅ **DO** use skeleton loading for network operations
- ✅ **DO** disable network-dependent features when offline
- ❌ **DON'T** hide connectivity issues from users

### 3. Error Handling
- ✅ **DO** provide specific error messages for different network issues
- ✅ **DO** log network errors with context for debugging
- ✅ **DO** implement exponential backoff for retries
- ❌ **DON'T** retry non-retryable errors (401, 403, etc.)

### 4. User Experience
- ✅ **DO** cache data locally for offline usage
- ✅ **DO** show clear indicators when using cached/mock data
- ✅ **DO** auto-retry operations when connectivity is restored
- ❌ **DON'T** block the UI while checking connectivity

## 🔧 Configuration

### Connectivity Service Settings
```dart
// In ConnectivityService._startPeriodicConnectivityCheck()
Timer.periodic(const Duration(seconds: 30), (timer) {
  // Adjust check frequency as needed
});
```

### Retry Configuration
```dart
// Default retry settings in BaseRepository
safeDbCallWithRetry(
  maxRetries: 3,                    // Adjust based on operation criticality
  retryDelay: Duration(seconds: 2), // Exponential backoff applied automatically
);
```

### Timeout Settings
```dart
// In ConnectivityService._checkInternetConnectivity()
final response = await http.get(
  Uri.parse(url),
  headers: {'Connection': 'close'},
).timeout(const Duration(seconds: 5)); // Adjust timeout as needed
```

## 🐛 Troubleshooting

### Common Issues

1. **ConnectivityBloc not found**
   - Ensure ConnectivityBloc is provided in your widget tree
   - Check that you're accessing it within the correct BuildContext

2. **Fallback data not showing**
   - Verify that your repository extends BaseRepository
   - Ensure fallback data is properly implemented in your repository methods

3. **Infinite retry loops**
   - Check that you're not retrying non-retryable errors
   - Verify maxRetries is set appropriately

4. **UI not updating on connectivity changes**
   - Ensure you're using BlocBuilder or BlocListener for ConnectivityBloc
   - Check that ConnectivityStarted event is dispatched on app start

### Debug Logging

The implementation includes comprehensive debug logging:
- `[ConnectivityService]` - Connectivity monitoring logs
- `[ConnectivityBloc]` - Bloc state changes
- `[Repository]` - Database operation logs

Enable debug logging in development to track connectivity issues.

## 📈 Future Enhancements

1. **Offline Data Sync** - Queue operations for execution when connectivity is restored
2. **Background Sync** - Sync cached data with server when app comes to foreground
3. **Bandwidth Detection** - Adjust data loading strategies based on connection quality
4. **Analytics Integration** - Track connectivity issues for app optimization
5. **Smart Caching** - Implement TTL-based cache invalidation strategies

## 🔗 Related Files

- `lib/core/services/connectivity_service.dart` - Core connectivity monitoring
- `lib/core/blocs/connectivity/` - Connectivity state management
- `lib/core/repositories/base_repository.dart` - Network-aware database operations
- `lib/core/utils/app_exception.dart` - Enhanced error types and handling
- `lib/presentation/widgets/connectivity_banner.dart` - UI components
- `lib/presentation/screens/home_screen.dart` - Example implementation
- `lib/main.dart` - App-level connectivity bloc setup

---

This implementation provides a robust foundation for handling network connectivity issues in your Flutter app. Users will have a smooth experience even when network conditions are poor, with clear feedback about connectivity status and automatic recovery when possible. 