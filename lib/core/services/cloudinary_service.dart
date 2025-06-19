import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String cloudName = 'dg7rsus0g';
  static const String uploadPreset = 'managment_upload';
  
  // Reuse HTTP client for better performance
  static final http.Client _httpClient = http.Client();

  /// Uploads an image file to Cloudinary with optimizations
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['quality'] = 'auto:good'  // Automatic quality optimization
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await _httpClient.send(request);
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResult = json.decode(responseData);
        return jsonResult['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Uploads multiple images in truly parallel with progress tracking
  static Future<List<String>> uploadImagesInParallel(
    List<String> imagePaths, {
    Function(int completed, int total)? onProgress,
  }) async {
    if (imagePaths.isEmpty) return [];

    // Filter out already uploaded URLs
    final localImagePaths = imagePaths
        .where((path) => !path.startsWith('http'))
        .toList();
    
    final alreadyUploadedUrls = imagePaths
        .where((path) => path.startsWith('http'))
        .toList();

    if (localImagePaths.isEmpty) {
      return alreadyUploadedUrls;
    }

    int completed = 0;
    final List<String> uploadedUrls = [];

    // Create all upload tasks immediately for true parallelism
    final uploadTasks = localImagePaths.map((imagePath) async {
      try {
        final file = File(imagePath);
        final url = await uploadImage(file);
        
        // Update progress atomically
        completed++;
        onProgress?.call(completed, localImagePaths.length);
        
        return url;
      } catch (e) {
        debugPrint('Error uploading image $imagePath: $e');
        completed++;
        onProgress?.call(completed, localImagePaths.length);
        return null;
      }
    }).toList();

    // Execute ALL uploads simultaneously 
    final results = await Future.wait(uploadTasks);
    
    // Filter out null results and combine with already uploaded URLs
    uploadedUrls.addAll(alreadyUploadedUrls);
    uploadedUrls.addAll(results.whereType<String>());

    return uploadedUrls;
  }



  /// Get file size in MB
  static Future<double> getFileSizeInMB(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0.0;
    }
  }

  /// Validate image file
  static bool isValidImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension);
  }

  /// Get total size of multiple images
  static Future<double> getTotalSizeInMB(List<String> imagePaths) async {
    double totalSize = 0.0;
    for (final path in imagePaths) {
      if (!path.startsWith('http')) {
        totalSize += await getFileSizeInMB(path);
      }
    }
    return totalSize;
  }

  /// Clean up resources
  static void dispose() {
    _httpClient.close();
  }
}
