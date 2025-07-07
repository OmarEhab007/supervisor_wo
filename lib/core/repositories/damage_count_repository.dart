import 'package:supervisor_wo/core/repositories/base_repository.dart';
import 'package:supervisor_wo/models/damage_count_model.dart';
import 'package:supervisor_wo/models/school_model.dart';
import 'package:supervisor_wo/core/services/cloudinary_service.dart';
import 'package:supervisor_wo/core/services/upload_optimizer.dart';
import 'package:flutter/foundation.dart';

/// Repository for handling damage count data operations
class DamageCountRepository extends BaseRepository {
  /// Fetch schools assigned to the current supervisor for damage counting
  Future<List<School>> getDamageSchools() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();
        print(
            '🔍 DEBUG: Fetching schools for damage count supervisor: $userId');

        // Get assigned school IDs first
        final assignmentResponse = await client
            .from('supervisor_schools')
            .select('school_id')
            .eq('supervisor_id', userId);

        if (assignmentResponse.isEmpty) {
          print('🔍 DEBUG: No assignments found, returning empty list');
          return [];
        }

        final schoolIds = assignmentResponse
            .map((assignment) => assignment['school_id'] as String)
            .toList();

        print('🔍 DEBUG: Found school IDs: $schoolIds');

        // Query schools directly by IDs
        final response = await client
            .from('schools')
            .select('id, name, address')
            .inFilter('id', schoolIds)
            .order('name', ascending: true);

        print('🔍 DEBUG: Found ${response.length} assigned schools');

        final schools = response.map<School>((data) {
          return School(
            id: data['id'] as String,
            name: data['name'] as String,
            address: data['address'] as String? ?? '',
            reportsCount: 0,
            hasEmergencyReports: false,
          );
        }).toList();

        return schools;
      },
      fallback: <School>[],
      context: 'Fetching assigned damage count schools',
    );
  }

  /// Save damage count data to database
  Future<bool> saveDamageCount(DamageCountModel damageCount) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Prepare data for insertion
        final data = {
          'id': damageCount.id,
          'school_id': damageCount.schoolId,
          'school_name': damageCount.schoolName,
          'supervisor_id': userId,
          'item_counts': damageCount.itemCounts,
          'section_photos': damageCount.sectionPhotos,
          'status': damageCount.status,
          'created_at': damageCount.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await insertInto('damage_counts', data);
        return true;
      },
      fallback: false,
      context: 'Saving damage count data',
    );
  }

  /// Update existing damage count data
  Future<bool> updateDamageCount(DamageCountModel damageCount) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Prepare data for update
        final data = {
          'school_id': damageCount.schoolId,
          'school_name': damageCount.schoolName,
          'supervisor_id': userId,
          'item_counts': damageCount.itemCounts,
          'status': damageCount.status,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await updateTable('damage_counts', data).eq('id', damageCount.id);
        return true;
      },
      fallback: false,
      context: 'Updating damage count data',
    );
  }

  /// Fetch damage count data for a specific school
  Future<DamageCountModel?> getDamageCountBySchool(String schoolId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await selectFrom('damage_counts')
            .eq('school_id', schoolId)
            .eq('supervisor_id', userId)
            .order('created_at', ascending: false)
            .limit(1);

        if (response.isEmpty) return null;

        return DamageCountModel.fromMap(response.first);
      },
      fallback: null,
      context: 'Fetching damage count by school',
    );
  }

  /// Save damage count with photos
  Future<bool> saveDamageCountWithPhotos(
    DamageCountModel damageCount,
    Map<String, List<String>> sectionPhotos,
  ) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Upload photos first
        final uploadedPhotos = await _uploadSectionPhotos(sectionPhotos);

        // Create updated damage count with uploaded photo URLs
        final updatedDamageCount = damageCount.copyWith(
          sectionPhotos: uploadedPhotos,
        );

        // Save damage count data
        final data = {
          'id': updatedDamageCount.id,
          'school_id': updatedDamageCount.schoolId,
          'school_name': updatedDamageCount.schoolName,
          'supervisor_id': userId,
          'item_counts': updatedDamageCount.itemCounts,
          'section_photos': updatedDamageCount.sectionPhotos,
          'status': updatedDamageCount.status,
          'created_at': updatedDamageCount.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await insertInto('damage_counts', data);

        // Save individual photo records
        await _savePhotoRecords(updatedDamageCount.id, uploadedPhotos);

        return true;
      },
      fallback: false,
      context: 'Saving damage count with photos',
    );
  }

  /// Fetch all damage count records for current supervisor
  Future<List<DamageCountModel>> getDamageCountsForSupervisor() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await selectFrom('damage_counts')
            .eq('supervisor_id', userId)
            .order('created_at', ascending: false);

        return response
            .map<DamageCountModel>((data) => DamageCountModel.fromMap(data))
            .toList();
      },
      fallback: <DamageCountModel>[],
      context: 'Fetching damage counts',
    );
  }

  /// Delete damage count record
  Future<bool> deleteDamageCount(String damageCountId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        await deleteFrom('damage_counts')
            .eq('id', damageCountId)
            .eq('supervisor_id', userId);

        return true;
      },
      fallback: false,
      context: 'Deleting damage count',
    );
  }

  /// Upload photos for each section - OPTIMIZED
  Future<Map<String, List<String>>> _uploadSectionPhotos(
    Map<String, List<String>> sectionPhotos,
  ) async {
    if (sectionPhotos.isEmpty) return {};

    // Use optimized uploader with progress tracking
    return await UploadOptimizer.optimizedSectionPhotoUpload(
      sectionPhotos,
      onProgress: (completed, total, currentSection) {
        debugPrint(
            '📸 Upload progress: $completed/$total photos - Section: $currentSection');
      },
    );
  }

  /// Save photo records to separate table - OPTIMIZED
  Future<void> _savePhotoRecords(
    String damageCountId,
    Map<String, List<String>> sectionPhotos,
  ) async {
    if (sectionPhotos.isEmpty) return;

    // Create all photo records
    final photoRecords = UploadOptimizer.createPhotoRecords(
      damageCountId,
      'damage_count_id',
      sectionPhotos,
      includeOrder: false,
    );

    // Batch insert for better performance
    await UploadOptimizer.batchInsertPhotoRecords(
      photoRecords,
      (record) async {
        await insertInto('damage_count_photos', record);
      },
    );
  }
}
