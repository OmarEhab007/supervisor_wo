import 'package:flutter/foundation.dart';
import 'package:supervisor_wo/core/repositories/base_repository.dart';
import 'package:supervisor_wo/models/school_achievement_model.dart';
import 'package:supervisor_wo/models/school_model.dart';

/// Repository for handling school achievement operations
class SchoolAchievementRepository extends BaseRepository {
  /// Save a new achievement to the database
  Future<bool> saveAchievement(SchoolAchievementModel achievement) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // First insert as draft to get the ID
        final draftData = {
          'school_id': achievement.schoolId,
          'school_name': achievement.schoolName,
          'supervisor_id': userId,
          'achievement_type': achievement.achievementType.value,
          'status': 'draft', // Always start as draft
          'photos': achievement.photos,
          'notes': achievement.notes,
          'created_at': achievement.createdAt.toIso8601String(),
        };

        // Insert the main achievement record and get the ID
        final response = await client
            .from('school_achievements')
            .insert(draftData)
            .select('id')
            .single();

        final achievementId = response['id'] as String;

        // If the achievement should be submitted, update the status to trigger the database trigger
        if (achievement.status == AchievementStatus.submitted) {
          await client
              .from('school_achievements')
              .update({'status': 'submitted'}).eq('id', achievementId);

          debugPrint('Updated achievement $achievementId to submitted status');
        }

        // Insert individual photo records if there are photos
        if (achievement.photos.isNotEmpty) {
          final photoRecords = achievement.photos
              .map((photoUrl) => {
                    'achievement_id': achievementId,
                    'school_id': achievement.schoolId,
                    'school_name': achievement.schoolName,
                    'achievement_type': achievement.achievementType.value,
                    'supervisor_id': userId,
                    'photo_url': photoUrl,
                    'photo_description':
                        '${achievement.achievementType.arabicName} - ${achievement.schoolName}',
                    'file_size': null, // Will be populated later if needed
                    'mime_type': 'image/jpeg', // Default for compressed images
                    'upload_timestamp': DateTime.now().toIso8601String(),
                  })
              .toList();

          await client.from('achievement_photos').insert(photoRecords);
        }

        return true;
      },
      fallback: false,
      context: 'Saving school achievement',
    );
  }

  /// Update an existing achievement
  Future<bool> updateAchievement(SchoolAchievementModel achievement) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final data = {
          'school_id': achievement.schoolId,
          'school_name': achievement.schoolName,
          'supervisor_id': userId,
          'achievement_type': achievement.achievementType.value,
          'status': achievement.status.value,
          'photos': achievement.photos,
          'notes': achievement.notes,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await client
            .from('school_achievements')
            .update(data)
            .eq('id', achievement.id)
            .eq('supervisor_id', userId);
        return true;
      },
      fallback: false,
      context: 'Updating school achievement',
    );
  }

  /// Submit an achievement (change status to submitted)
  Future<bool> submitAchievement(String achievementId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final data = {
          'status': AchievementStatus.submitted.value,
          'updated_at': DateTime.now().toIso8601String(),
          'submitted_at': DateTime.now().toIso8601String(),
        };

        await client
            .from('school_achievements')
            .update(data)
            .eq('id', achievementId)
            .eq('supervisor_id', userId);

        return true;
      },
      fallback: false,
      context: 'Submitting school achievement',
    );
  }

  /// Get all achievements for the current supervisor
  Future<List<SchoolAchievementModel>> getAchievements() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('school_achievements')
            .select('*')
            .eq('supervisor_id', userId)
            .order('created_at', ascending: false);

        return response
            .map<SchoolAchievementModel>(
                (data) => SchoolAchievementModel.fromMap(data))
            .toList();
      },
      fallback: <SchoolAchievementModel>[],
      context: 'Fetching achievements',
    );
  }

  /// Get achievements for a specific school
  Future<List<SchoolAchievementModel>> getSchoolAchievements(
      String schoolId) async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('school_achievements')
            .select('*')
            .eq('supervisor_id', userId)
            .eq('school_id', schoolId)
            .order('created_at', ascending: false);

        return response
            .map<SchoolAchievementModel>(
                (data) => SchoolAchievementModel.fromMap(data))
            .toList();
      },
      fallback: <SchoolAchievementModel>[],
      context: 'Fetching school achievements',
    );
  }

  /// Get achievements for a specific school and type
  Future<List<SchoolAchievementModel>> getSchoolAchievementsByType(
      String schoolId, AchievementType type) async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('school_achievements')
            .select('*')
            .eq('supervisor_id', userId)
            .eq('school_id', schoolId)
            .eq('achievement_type', type.value)
            .order('created_at', ascending: false);

        return response
            .map<SchoolAchievementModel>(
                (data) => SchoolAchievementModel.fromMap(data))
            .toList();
      },
      fallback: <SchoolAchievementModel>[],
      context: 'Fetching school achievements by type',
    );
  }

  /// Get the latest submission date for each achievement type per school
  Future<Map<String, Map<String, DateTime?>>> getLatestSubmissionDates() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('school_achievements')
            .select('school_id, achievement_type, submitted_at')
            .eq('supervisor_id', userId)
            .eq('status', 'submitted')
            .not('submitted_at', 'is', null)
            .order('submitted_at', ascending: false);

        final result = <String, Map<String, DateTime?>>{};

        for (final row in response) {
          final schoolId = row['school_id'] as String;
          final achievementType = row['achievement_type'] as String;
          final submittedAt = DateTime.parse(row['submitted_at'] as String);

          if (!result.containsKey(schoolId)) {
            result[schoolId] = {};
          }

          // Only keep the latest submission for each type
          if (!result[schoolId]!.containsKey(achievementType) ||
              submittedAt.isAfter(result[schoolId]![achievementType]!)) {
            result[schoolId]![achievementType] = submittedAt;
          }
        }

        return result;
      },
      fallback: <String, Map<String, DateTime?>>{},
      context: 'Fetching latest submission dates',
    );
  }

  /// Get achievement statistics for the supervisor
  Future<Map<String, dynamic>> getAchievementStatistics() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('school_achievements')
            .select('achievement_type, status')
            .eq('supervisor_id', userId);

        final stats = <String, dynamic>{
          'total': response.length,
          'submitted': 0,
          'draft': 0,
          'maintenance_achievement': 0,
          'ac_achievement': 0,
          'checklist': 0,
        };

        for (final row in response) {
          final status = row['status'] as String;
          final type = row['achievement_type'] as String;

          if (status == 'submitted') stats['submitted']++;
          if (status == 'draft') stats['draft']++;

          stats[type] = (stats[type] ?? 0) + 1;
        }

        return stats;
      },
      fallback: <String, dynamic>{
        'total': 0,
        'submitted': 0,
        'draft': 0,
        'maintenance_achievement': 0,
        'ac_achievement': 0,
        'checklist': 0,
      },
      context: 'Fetching achievement statistics',
    );
  }

  /// Get photos with achievement type information
  Future<List<Map<String, dynamic>>> getPhotosWithAchievementType() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('achievement_photos')
            .select('''
              *,
              school_achievements!inner(
                achievement_type,
                school_name,
                status,
                submitted_at
              )
            ''')
            .eq('school_achievements.supervisor_id', userId)
            .order('upload_timestamp', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      },
      fallback: <Map<String, dynamic>>[],
      context: 'Fetching photos with achievement type',
    );
  }

  /// Delete an achievement
  Future<bool> deleteAchievement(String achievementId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        await client
            .from('school_achievements')
            .delete()
            .eq('id', achievementId)
            .eq('supervisor_id', userId);

        return true;
      },
      fallback: false,
      context: 'Deleting achievement',
    );
  }

  /// Save achievement photo metadata
  Future<bool> saveAchievementPhoto(AchievementPhotoModel photo) async {
    return await safeDbCall(
      () async {
        final data = photo.toMap();
        await insertInto('achievement_photos', data);
        return true;
      },
      fallback: false,
      context: 'Saving achievement photo metadata',
    );
  }

  /// Get photos for an achievement
  Future<List<AchievementPhotoModel>> getAchievementPhotos(
      String achievementId) async {
    return await safeNetworkDbCall(
      () async {
        final response = await client
            .from('achievement_photos')
            .select('*')
            .eq('achievement_id', achievementId)
            .order('upload_timestamp', ascending: false);

        return response
            .map<AchievementPhotoModel>(
                (data) => AchievementPhotoModel.fromMap(data))
            .toList();
      },
      fallback: <AchievementPhotoModel>[],
      context: 'Fetching achievement photos',
    );
  }

  /// Delete achievement photo
  Future<bool> deleteAchievementPhoto(String photoId) async {
    return await safeDbCall(
      () async {
        await client.from('achievement_photos').delete().eq('id', photoId);
        return true;
      },
      fallback: false,
      context: 'Deleting achievement photo',
    );
  }

  /// Get achievement history for a school (submitted achievements only)
  Future<List<SchoolAchievementModel>> getSchoolAchievementHistory(
      String schoolId) async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('school_achievements')
            .select('*')
            .eq('supervisor_id', userId)
            .eq('school_id', schoolId)
            .eq('status', 'submitted')
            .order('submitted_at', ascending: false);

        return response
            .map<SchoolAchievementModel>(
                (data) => SchoolAchievementModel.fromMap(data))
            .toList();
      },
      fallback: <SchoolAchievementModel>[],
      context: 'Fetching school achievement history',
    );
  }

  /// Check if an achievement type has been submitted for a school today
  Future<bool> hasSubmittedToday(String schoolId, AchievementType type) async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final response = await client
            .from('school_achievements')
            .select('id')
            .eq('supervisor_id', userId)
            .eq('school_id', schoolId)
            .eq('achievement_type', type.value)
            .eq('status', 'submitted')
            .gte('submitted_at', startOfDay.toIso8601String())
            .lt('submitted_at', endOfDay.toIso8601String())
            .limit(1);

        return response.isNotEmpty;
      },
      fallback: false,
      context: 'Checking if submitted today',
    );
  }

  /// Get schools with their latest achievement submission dates
  Future<List<School>> getSchoolsWithAchievementDates() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Get supervisor's assigned schools
        final schoolsResponse = await client
            .from('supervisor_schools')
            .select('school_id, schools(id, name, address)')
            .eq('supervisor_id', userId);

        final schools = <School>[];

        for (final schoolAssignment in schoolsResponse) {
          final schoolData = schoolAssignment['schools'];
          if (schoolData != null) {
            final schoolId = schoolData['id'] as String;

            // Get latest achievement submission for this school
            final achievementResponse = await client
                .from('school_achievements')
                .select('submitted_at, achievement_type')
                .eq('supervisor_id', userId)
                .eq('school_id', schoolId)
                .eq('status', 'submitted')
                .not('submitted_at', 'is', null)
                .order('submitted_at', ascending: false)
                .limit(1);

            DateTime? lastSubmission;
            String? lastSubmissionSource;

            if (achievementResponse.isNotEmpty) {
              lastSubmission = DateTime.parse(
                  achievementResponse.first['submitted_at'] as String);
              final type =
                  achievementResponse.first['achievement_type'] as String;
              lastSubmissionSource =
                  AchievementType.fromString(type).arabicName;
            }

            schools.add(School(
              id: schoolId,
              name: schoolData['name'] as String,
              address: schoolData['address'] as String? ?? '',
              reportsCount: 0,
              hasEmergencyReports: false,
              lastVisitDate: lastSubmission,
              lastVisitSource: lastSubmissionSource,
            ));
          }
        }

        return schools;
      },
      fallback: <School>[],
      context: 'Fetching schools with achievement dates',
    );
  }

  /// Get all photos for a specific school
  Future<List<Map<String, dynamic>>> getSchoolPhotos(String schoolId) async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('achievement_photos')
            .select('*')
            .eq('school_id', schoolId)
            .eq('supervisor_id', userId)
            .order('upload_timestamp', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      },
      fallback: <Map<String, dynamic>>[],
      context: 'Fetching school photos',
    );
  }

  /// Get photos for a specific school and achievement type
  Future<List<Map<String, dynamic>>> getSchoolPhotosByType(
      String schoolId, AchievementType type) async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('achievement_photos')
            .select('*')
            .eq('school_id', schoolId)
            .eq('achievement_type', type.value)
            .eq('supervisor_id', userId)
            .order('upload_timestamp', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      },
      fallback: <Map<String, dynamic>>[],
      context: 'Fetching school photos by type',
    );
  }

  /// Get photo counts by school and achievement type
  Future<Map<String, Map<String, int>>> getSchoolPhotoCountsByType() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await client
            .from('achievement_photos')
            .select('school_id, school_name, achievement_type')
            .eq('supervisor_id', userId);

        final result = <String, Map<String, int>>{};

        for (final row in response) {
          final schoolId = row['school_id'] as String;
          final achievementType = row['achievement_type'] as String;

          if (!result.containsKey(schoolId)) {
            result[schoolId] = {
              'maintenance_achievement': 0,
              'ac_achievement': 0,
              'checklist': 0,
            };
          }

          result[schoolId]![achievementType] =
              (result[schoolId]![achievementType] ?? 0) + 1;
        }

        return result;
      },
      fallback: <String, Map<String, int>>{},
      context: 'Fetching school photo counts by type',
    );
  }

  /// Get schools with their achievement photo summary
  Future<List<Map<String, dynamic>>> getSchoolsWithPhotoSummary() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Get supervisor's assigned schools
        final schoolsResponse = await client
            .from('supervisor_schools')
            .select('school_id, schools(id, name, address)')
            .eq('supervisor_id', userId);

        final result = <Map<String, dynamic>>[];

        for (final schoolAssignment in schoolsResponse) {
          final schoolData = schoolAssignment['schools'];
          if (schoolData != null) {
            final schoolId = schoolData['id'] as String;
            final schoolName = schoolData['name'] as String;

            // Get photo counts for this school
            final photoResponse = await client
                .from('achievement_photos')
                .select('achievement_type, upload_timestamp')
                .eq('school_id', schoolId)
                .eq('supervisor_id', userId)
                .order('upload_timestamp', ascending: false);

            int maintenanceCount = 0;
            int acCount = 0;
            int checklistCount = 0;
            DateTime? latestUpload;

            for (final photo in photoResponse) {
              final type = photo['achievement_type'] as String;
              final uploadTime =
                  DateTime.parse(photo['upload_timestamp'] as String);

              if (latestUpload == null || uploadTime.isAfter(latestUpload)) {
                latestUpload = uploadTime;
              }

              switch (type) {
                case 'maintenance_achievement':
                  maintenanceCount++;
                  break;
                case 'ac_achievement':
                  acCount++;
                  break;
                case 'checklist':
                  checklistCount++;
                  break;
              }
            }

            result.add({
              'school_id': schoolId,
              'school_name': schoolName,
              'maintenance_photos': maintenanceCount,
              'ac_photos': acCount,
              'checklist_photos': checklistCount,
              'total_photos': maintenanceCount + acCount + checklistCount,
              'latest_upload': latestUpload?.toIso8601String(),
            });
          }
        }

        // Sort by latest upload (most recent first)
        result.sort((a, b) {
          final aTime = a['latest_upload'] as String?;
          final bTime = b['latest_upload'] as String?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
        });

        return result;
      },
      fallback: <Map<String, dynamic>>[],
      context: 'Fetching schools with photo summary',
    );
  }
}
