import 'dart:io';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class OptimizedCloudinaryService {
  static const String cloudName = 'dg7rsus0g';
  static const String uploadPreset = 'managment_upload';

  // Reuse HTTP client for better performance
  static final http.Client _httpClient = http.Client();

  /// Compress image file to reduce upload time
  static Future<File> compressImage(String imagePath) async {
    try {
      final originalFile = File(imagePath);
      final bytes = await originalFile.readAsBytes();

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) return originalFile;

      // Resize if too large (max 1920x1080 for good quality/size balance)
      img.Image resized = image;
      if (image.width > 1920 || image.height > 1080) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: 1920);
        } else {
          resized = img.copyResize(image, height: 1080);
        }
      }

      // Compress with 80% quality for good balance
      final compressedBytes = img.encodeJpg(resized, quality: 80);

      // Save compressed version
      final compressedPath =
          imagePath.replaceAll(path.extension(imagePath), '_compressed.jpg');
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      final originalSize = bytes.length / (1024 * 1024);
      final compressedSize = compressedBytes.length / (1024 * 1024);

      debugPrint(
          'Image compressed: ${originalSize.toStringAsFixed(2)}MB → ${compressedSize.toStringAsFixed(2)}MB');

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return File(imagePath); // Return original if compression fails
    }
  }

  /// Upload single image with compression
  static Future<String?> uploadImageOptimized(String imagePath) async {
    try {
      // Skip compression for already uploaded URLs
      if (imagePath.startsWith('http')) return imagePath;

      // Compress image first
      final compressedFile = await compressImage(imagePath);

      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset;

      // Add file with proper content type
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        compressedFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      final response = await _httpClient.send(request);

      // Clean up compressed file if different from original
      if (compressedFile.path != imagePath) {
        try {
          await compressedFile.delete();
        } catch (e) {
          debugPrint('Could not delete compressed file: $e');
        }
      }

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResult = json.decode(responseData);
        return jsonResult['secure_url'] as String?;
      } else {
        final responseData = await response.stream.bytesToString();
        debugPrint(
            'Cloudinary upload failed with status: ${response.statusCode}');
        debugPrint('Response body: $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Ultra-fast parallel upload of ALL photos across ALL sections
  static Future<Map<String, List<String>>> uploadAllSectionPhotosOptimized(
    Map<String, List<String>> sectionPhotos, {
    Function(int completed, int total)? onProgress,
  }) async {
    if (sectionPhotos.isEmpty) return {};

    // Flatten all photos into a single list for maximum parallelism
    final List<MapEntry<String, String>> allPhotosWithSections = [];
    final Map<String, List<String>> result = {};

    // Initialize result map
    for (final section in sectionPhotos.keys) {
      result[section] = [];
    }

    // Collect all photos with their section info
    for (final entry in sectionPhotos.entries) {
      final sectionKey = entry.key;
      final photoPaths = entry.value;

      for (final photoPath in photoPaths) {
        allPhotosWithSections.add(MapEntry(sectionKey, photoPath));
      }
    }

    if (allPhotosWithSections.isEmpty) return result;

    debugPrint(
        '🚀 Starting optimized upload of ${allPhotosWithSections.length} photos across ${sectionPhotos.length} sections');

    int completed = 0;
    final int total = allPhotosWithSections.length;

    // Create upload tasks for ALL photos at once (maximum parallelism)
    final uploadTasks = allPhotosWithSections.map((photoWithSection) async {
      try {
        final sectionKey = photoWithSection.key;
        final photoPath = photoWithSection.value;

        final uploadedUrl = await uploadImageOptimized(photoPath);

        // Update progress
        completed++;
        onProgress?.call(completed, total);

        return MapEntry(sectionKey, uploadedUrl);
      } catch (e) {
        debugPrint('Error uploading photo: $e');
        completed++;
        onProgress?.call(completed, total);
        return MapEntry(photoWithSection.key, null);
      }
    }).toList();

    // Execute ALL uploads simultaneously (true parallelism)
    final uploadResults = await Future.wait(uploadTasks);

    // Group results back by section
    for (final resultEntry in uploadResults) {
      final sectionKey = resultEntry.key;
      final uploadedUrl = resultEntry.value;

      if (uploadedUrl != null) {
        result[sectionKey]!.add(uploadedUrl);
      }
    }

    debugPrint(
        '✅ Upload completed: ${completed}/${total} photos uploaded successfully');

    return result;
  }

  /// Batch insert photo records for better performance
  static Future<void> batchSavePhotoRecords(
    String countId,
    String tableName, // 'damage_count_photos' or 'maintenance_count_photos'
    String countIdField, // 'damage_count_id' or 'maintenance_count_id'
    Map<String, List<String>> sectionPhotos,
    Function(Map<String, dynamic>) insertFn,
  ) async {
    if (sectionPhotos.isEmpty) return;

    // Prepare all records for batch insert
    final List<Map<String, dynamic>> photoRecords = [];

    for (final entry in sectionPhotos.entries) {
      final sectionKey = entry.key;
      final photoUrls = entry.value;

      for (int i = 0; i < photoUrls.length; i++) {
        photoRecords.add({
          countIdField: countId,
          'section_key': sectionKey,
          'photo_url': photoUrls[i],
          'photo_description': null,
          if (tableName == 'maintenance_count_photos') 'photo_order': i,
        });
      }
    }

    debugPrint('📸 Batch saving ${photoRecords.length} photo records');

    // Insert all records in batches of 50 for optimal performance
    const batchSize = 50;
    for (int i = 0; i < photoRecords.length; i += batchSize) {
      final batch = photoRecords.skip(i).take(batchSize).toList();

      // Execute batch insert - this could be optimized per repository
      for (final record in batch) {
        await insertFn(record);
      }
    }

    debugPrint('✅ Photo records saved successfully');
  }

  /// Get compression statistics
  static Future<Map<String, double>> getCompressionStats(
      List<String> imagePaths) async {
    double originalSize = 0.0;
    double compressedSize = 0.0;

    for (final imagePath in imagePaths) {
      if (!imagePath.startsWith('http')) {
        try {
          final originalFile = File(imagePath);
          final originalBytes = await originalFile.length();
          originalSize += originalBytes / (1024 * 1024);

          final compressedFile = await compressImage(imagePath);
          final compressedBytes = await compressedFile.length();
          compressedSize += compressedBytes / (1024 * 1024);

          // Clean up if compressed file is different
          if (compressedFile.path != imagePath) {
            await compressedFile.delete();
          }
        } catch (e) {
          debugPrint('Error calculating compression for $imagePath: $e');
        }
      }
    }

    return {
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'savings': originalSize - compressedSize,
      'compressionRatio':
          originalSize > 0 ? (compressedSize / originalSize) : 1.0,
    };
  }

  /// Clean up resources
  static void dispose() {
    _httpClient.close();
  }
}
