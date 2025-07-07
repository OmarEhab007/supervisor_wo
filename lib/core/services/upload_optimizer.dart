import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supervisor_wo/core/services/cloudinary_service.dart';

class UploadOptimizer {
  /// Optimize section photo uploads for maximum speed
  static Future<Map<String, List<String>>> optimizedSectionPhotoUpload(
    Map<String, List<String>> sectionPhotos, {
    Function(int completed, int total, String currentSection)? onProgress,
  }) async {
    if (sectionPhotos.isEmpty) return {};

    // Count total photos for progress tracking
    int totalPhotos = 0;
    for (final photos in sectionPhotos.values) {
      totalPhotos += photos.length;
    }

    if (totalPhotos == 0) return {};

    debugPrint(
        '🚀 Optimized upload starting: $totalPhotos photos across ${sectionPhotos.length} sections');

    // Flatten all photos for maximum parallelism
    final List<MapEntry<String, String>> allPhotoTasks = [];

    for (final entry in sectionPhotos.entries) {
      final sectionKey = entry.key;
      for (final photoPath in entry.value) {
        allPhotoTasks.add(MapEntry(sectionKey, photoPath));
      }
    }

    // Track progress
    int completed = 0;
    final Map<String, List<String>> result = {};

    // Initialize result sections
    for (final sectionKey in sectionPhotos.keys) {
      result[sectionKey] = [];
    }

    // Create upload tasks for ALL photos simultaneously
    final uploadFutures = allPhotoTasks.map((task) async {
      try {
        final sectionKey = task.key;
        final photoPath = task.value;

        // Use existing CloudinaryService but with better progress tracking
        final uploadedUrl =
            await CloudinaryService.uploadImage(File(photoPath));

        completed++;
        onProgress?.call(completed, totalPhotos, sectionKey);

        return MapEntry(sectionKey, uploadedUrl);
      } catch (e) {
        debugPrint('Upload failed for photo in section ${task.key}: $e');
        completed++;
        onProgress?.call(completed, totalPhotos, task.key);
        return MapEntry(task.key, null);
      }
    }).toList();

    // Execute ALL uploads in parallel
    final results = await Future.wait(uploadFutures);

    // Group results back by section
    for (final result_entry in results) {
      final sectionKey = result_entry.key;
      final uploadedUrl = result_entry.value;

      if (uploadedUrl != null) {
        result[sectionKey]!.add(uploadedUrl);
      }
    }

    debugPrint(
        '✅ Optimized upload completed: $completed/$totalPhotos photos uploaded');

    return result;
  }

  /// Batch database operations for better performance
  static Future<void> batchInsertPhotoRecords(
    List<Map<String, dynamic>> photoRecords,
    Future<void> Function(Map<String, dynamic>) insertFunction,
  ) async {
    if (photoRecords.isEmpty) return;

    debugPrint('📸 Batch inserting ${photoRecords.length} photo records');

    // Process in smaller batches to avoid overwhelming the database
    const batchSize = 20;

    for (int i = 0; i < photoRecords.length; i += batchSize) {
      final batch = photoRecords.skip(i).take(batchSize).toList();

      // Execute batch in parallel
      final insertFutures =
          batch.map((record) => insertFunction(record)).toList();
      await Future.wait(insertFutures);

      debugPrint(
          '📸 Inserted batch ${(i / batchSize).floor() + 1}/${(photoRecords.length / batchSize).ceil()}');
    }

    debugPrint('✅ All photo records inserted successfully');
  }

  /// Create photo records from section photos
  static List<Map<String, dynamic>> createPhotoRecords(
    String countId,
    String countIdField,
    Map<String, List<String>> sectionPhotos, {
    bool includeOrder = false,
  }) {
    final List<Map<String, dynamic>> photoRecords = [];

    for (final entry in sectionPhotos.entries) {
      final sectionKey = entry.key;
      final photoUrls = entry.value;

      for (int i = 0; i < photoUrls.length; i++) {
        final record = {
          countIdField: countId,
          'section_key': sectionKey,
          'photo_url': photoUrls[i],
          'photo_description': null,
        };

        if (includeOrder) {
          record['photo_order'] = i.toString();
        }

        photoRecords.add(record);
      }
    }

    return photoRecords;
  }

  /// Show upload progress statistics
  static String formatUploadProgress(
      int completed, int total, String currentSection) {
    final percentage =
        total > 0 ? (completed / total * 100).toStringAsFixed(0) : '0';
    return '$completed/$total photos uploaded ($percentage%) - Current: $currentSection';
  }
}
