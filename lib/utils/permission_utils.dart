import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Utility class for handling permissions in the app
class PermissionUtils {
  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(
        context,
        'Camera Permission',
        'Camera permission is required to take photos. Please enable it in app settings.',
      );
      return false;
    }
    return status.isGranted;
  }

  /// Request storage permission based on platform version
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // For Android 13+ (API 33+), we need to request READ_MEDIA_IMAGES
    // For older versions, we need to request STORAGE permission
    final permission = Platform.isAndroid && await _isAndroid13OrHigher()
        ? Permission.photos
        : Permission.storage;

    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(
        context,
        'Storage Permission',
        'Storage permission is required to access your photos. Please enable it in app settings.',
      );
      return false;
    }
    return status.isGranted;
  }

  /// Check if device is running Android 13 (API 33) or higher
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    return int.parse(await _getAndroidVersion()) >= 33;
  }

  /// Get Android version as a string
  static Future<String> _getAndroidVersion() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt.toString();
    } catch (e) {
      // Default to a safe value if we can't determine the version
      return '32'; // Assume Android 12 if we can't determine
    }
  }

  /// Show dialog when permission is permanently denied
  static void _showPermanentlyDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
