import 'package:supervisor_wo/core/repositories/base_repository.dart';
import 'package:supervisor_wo/models/maintenance_count_model.dart';
import 'package:supervisor_wo/models/school_model.dart';
import 'package:supervisor_wo/core/services/cloudinary_service.dart';
import 'package:supervisor_wo/core/services/upload_optimizer.dart';
import 'package:flutter/foundation.dart';

/// Repository for handling maintenance count data operations
class MaintenanceCountRepository extends BaseRepository {
  /// Fetch schools assigned to the current supervisor for maintenance counting
  Future<List<School>> getMaintenanceSchools() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();
        print('🔍 DEBUG: Fetching schools for supervisor: $userId');

        // First, let's check if there are any assignments for this supervisor
        final assignmentCheck = await client
            .from('supervisor_schools')
            .select('*')
            .eq('supervisor_id', userId);

        print(
            '🔍 DEBUG: Found ${assignmentCheck.length} assignments for supervisor');
        print('🔍 DEBUG: Assignments: $assignmentCheck');

        // Also check if there are schools in the database
        final allSchoolsCheck =
            await client.from('schools').select('id, name, address').limit(5);

        print('🔍 DEBUG: Sample schools in database: $allSchoolsCheck');

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

        print('🔍 DEBUG: Query response: $response');
        print('🔍 DEBUG: Found ${response.length} assigned schools');

        final schools = response.map<School>((data) {
          return School(
            id: data['id'] as String,
            name: data['name'] as String,
            address: data['address'] as String? ?? '',
            reportsCount: 0, // Not needed for maintenance counting
            hasEmergencyReports: false, // Not needed for maintenance counting
          );
        }).toList();

        print('🔍 DEBUG: Returning ${schools.length} schools');
        return schools;
      },
      fallback: _getMockSchools(),
      context: 'Fetching assigned maintenance schools',
    );
  }

  /// Fetch all schools in the system (for admin purposes)
  Future<List<School>> getAllSchools() async {
    return await safeNetworkDbCall(
      () async {
        final response =
            await selectFrom('schools').order('name', ascending: true);

        return response.map<School>((data) {
          return School(
            id: data['id'] as String,
            name: data['name'] as String,
            address: data['address'] as String? ?? '',
            reportsCount: 0,
            hasEmergencyReports: false,
          );
        }).toList();
      },
      fallback: _getMockSchools(),
      context: 'Fetching all schools',
    );
  }

  /// Fetch schools not assigned to the current supervisor
  Future<List<School>> getUnassignedSchools() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Get all schools
        final allSchoolsResponse =
            await selectFrom('schools').order('name', ascending: true);

        // Get assigned school IDs
        final assignedSchoolIds = await _getAssignedSchoolIdsList(userId);

        // Filter out assigned schools
        final unassignedSchools = allSchoolsResponse.where((schoolData) {
          final schoolId = schoolData['id'] as String;
          return !assignedSchoolIds.contains(schoolId);
        }).toList();

        return unassignedSchools.map<School>((data) {
          return School(
            id: data['id'] as String,
            name: data['name'] as String,
            address: data['address'] as String? ?? '',
            reportsCount: 0,
            hasEmergencyReports: false,
          );
        }).toList();
      },
      fallback: <School>[],
      context: 'Fetching unassigned schools',
    );
  }

  /// Helper method to get school IDs assigned to a supervisor as List
  Future<List<String>> _getAssignedSchoolIdsList(String supervisorId) async {
    final response = await client
        .from('supervisor_schools')
        .select('school_id')
        .eq('supervisor_id', supervisorId);

    return response.map<String>((row) => row['school_id'] as String).toList();
  }

  /// Debug method to test database connectivity and data
  Future<void> debugDatabaseConnection() async {
    try {
      final userId = requireAuthenticatedUser();
      print('🔍 DEBUG: Current user ID: $userId');

      // Test database connection info
      print('🔍 DEBUG: Testing database connection...');
      print('🔍 DEBUG: Current user: ${client.auth.currentUser?.email}');

      // Test 1: Check if schools table exists and has data
      print('🔍 DEBUG: Testing schools table...');
      final schoolsTest =
          await client.from('schools').select('id, name, address').limit(3);
      print('🔍 DEBUG: Schools table test result: $schoolsTest');

      // Test 2: Check if supervisor_schools table exists and has data
      print('🔍 DEBUG: Testing supervisor_schools table...');
      final supervisorSchoolsTest =
          await client.from('supervisor_schools').select('*').limit(3);
      print(
          '🔍 DEBUG: supervisor_schools table test result: $supervisorSchoolsTest');

      // Test 3: Check assignments for current user
      print('🔍 DEBUG: Testing assignments for current user...');
      final userAssignments = await client
          .from('supervisor_schools')
          .select('*')
          .eq('supervisor_id', userId);
      print('🔍 DEBUG: Current user assignments: $userAssignments');

      // Test 4: Try the original join query step by step
      print('🔍 DEBUG: Testing join query...');
      final joinTest = await client
          .from('schools')
          .select('id, name, address, supervisor_schools(*)')
          .limit(3);
      print('🔍 DEBUG: Join query test result: $joinTest');

      // Test 5: Check RLS status
      try {
        final rlsCheck = await client.rpc('check_rls_status');
        print('🔍 DEBUG: RLS status: $rlsCheck');
      } catch (e) {
        print('🔍 DEBUG: Could not check RLS status: $e');
      }
    } catch (e) {
      print('🔍 DEBUG: Error in database test: $e');
    }
  }

  /// Assign a school to the current supervisor
  Future<bool> assignSchoolToSupervisor(String schoolId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Check if assignment already exists
        final existingAssignment = await client
            .from('supervisor_schools')
            .select()
            .eq('supervisor_id', userId)
            .eq('school_id', schoolId)
            .limit(1);

        if (existingAssignment.isNotEmpty) {
          return true; // Already assigned
        }

        // Create new assignment
        await client.from('supervisor_schools').insert({
          'supervisor_id': userId,
          'school_id': schoolId,
          'assigned_at': DateTime.now().toIso8601String(),
        });

        return true;
      },
      fallback: false,
      context: 'Assigning school to supervisor',
    );
  }

  /// Remove school assignment from current supervisor
  Future<bool> unassignSchoolFromSupervisor(String schoolId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        await client
            .from('supervisor_schools')
            .delete()
            .eq('supervisor_id', userId)
            .eq('school_id', schoolId);

        return true;
      },
      fallback: false,
      context: 'Unassigning school from supervisor',
    );
  }

  /// Save maintenance count data to database
  Future<bool> saveMaintenanceCount(
      MaintenanceCountModel maintenanceCount) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Prepare data for insertion
        final data = {
          'id': maintenanceCount.id,
          'school_id': maintenanceCount.schoolId,
          'school_name': maintenanceCount.schoolName,
          'supervisor_id': userId,
          'item_counts': maintenanceCount.itemCounts,
          'text_answers': maintenanceCount.textAnswers,
          'yes_no_answers': maintenanceCount.yesNoAnswers,
          'yes_no_with_counts': maintenanceCount.yesNoWithCounts,
          'survey_answers': maintenanceCount.surveyAnswers,
          'maintenance_notes': maintenanceCount.maintenanceNotes,
          'fire_safety_alarm_panel_data':
              maintenanceCount.fireSafetyAlarmPanelData,
          'fire_safety_condition_only_data':
              maintenanceCount.fireSafetyConditionOnlyData,
          'fire_safety_expiry_dates': maintenanceCount.fireSafetyExpiryDates,
          'section_photos': maintenanceCount.sectionPhotos,
          'status': maintenanceCount.status,
          'created_at': maintenanceCount.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await insertInto('maintenance_counts', data);
        return true;
      },
      fallback: false,
      context: 'Saving maintenance count data',
    );
  }

  /// Save maintenance count with photos
  Future<bool> saveMaintenanceCountWithPhotos(
    MaintenanceCountModel maintenanceCount,
    Map<String, List<String>> sectionPhotos,
  ) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Upload photos first
        final uploadedPhotos = await _uploadSectionPhotos(sectionPhotos);

        // Create updated maintenance count with uploaded photo URLs
        final updatedMaintenanceCount = maintenanceCount.copyWith(
          sectionPhotos: uploadedPhotos,
        );

        // Save maintenance count data
        final data = {
          'id': updatedMaintenanceCount.id,
          'school_id': updatedMaintenanceCount.schoolId,
          'school_name': updatedMaintenanceCount.schoolName,
          'supervisor_id': userId,
          'item_counts': updatedMaintenanceCount.itemCounts,
          'text_answers': updatedMaintenanceCount.textAnswers,
          'yes_no_answers': updatedMaintenanceCount.yesNoAnswers,
          'yes_no_with_counts': updatedMaintenanceCount.yesNoWithCounts,
          'survey_answers': updatedMaintenanceCount.surveyAnswers,
          'maintenance_notes': updatedMaintenanceCount.maintenanceNotes,
          'fire_safety_alarm_panel_data':
              updatedMaintenanceCount.fireSafetyAlarmPanelData,
          'fire_safety_condition_only_data':
              updatedMaintenanceCount.fireSafetyConditionOnlyData,
          'fire_safety_expiry_dates':
              updatedMaintenanceCount.fireSafetyExpiryDates,
          'section_photos': updatedMaintenanceCount.sectionPhotos,
          'status': updatedMaintenanceCount.status,
          'created_at': updatedMaintenanceCount.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await insertInto('maintenance_counts', data);

        // Save individual photo records
        await _savePhotoRecords(updatedMaintenanceCount.id, uploadedPhotos);

        return true;
      },
      fallback: false,
      context: 'Saving maintenance count with photos',
    );
  }

  /// Update existing maintenance count data
  Future<bool> updateMaintenanceCount(
      MaintenanceCountModel maintenanceCount) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        // Prepare data for update
        final data = {
          'school_id': maintenanceCount.schoolId,
          'school_name': maintenanceCount.schoolName,
          'supervisor_id': userId,
          'item_counts': maintenanceCount.itemCounts,
          'text_answers': maintenanceCount.textAnswers,
          'yes_no_answers': maintenanceCount.yesNoAnswers,
          'yes_no_with_counts': maintenanceCount.yesNoWithCounts,
          'survey_answers': maintenanceCount.surveyAnswers,
          'maintenance_notes': maintenanceCount.maintenanceNotes,
          'fire_safety_alarm_panel_data':
              maintenanceCount.fireSafetyAlarmPanelData,
          'fire_safety_condition_only_data':
              maintenanceCount.fireSafetyConditionOnlyData,
          'fire_safety_expiry_dates': maintenanceCount.fireSafetyExpiryDates,
          'status': maintenanceCount.status,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await updateTable('maintenance_counts', data)
            .eq('id', maintenanceCount.id);
        return true;
      },
      fallback: false,
      context: 'Updating maintenance count data',
    );
  }

  /// Fetch maintenance count data for a specific school
  Future<MaintenanceCountModel?> getMaintenanceCountBySchool(
      String schoolId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await selectFrom('maintenance_counts')
            .eq('school_id', schoolId)
            .eq('supervisor_id', userId)
            .order('created_at', ascending: false)
            .limit(1);

        if (response.isEmpty) return null;

        return MaintenanceCountModel.fromMap(response.first);
      },
      fallback: null,
      context: 'Fetching maintenance count by school',
    );
  }

  /// Fetch all maintenance count records for current supervisor
  Future<List<MaintenanceCountModel>> getMaintenanceCounts() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        final response = await selectFrom('maintenance_counts')
            .eq('supervisor_id', userId)
            .order('created_at', ascending: false);

        return response
            .map<MaintenanceCountModel>(
                (data) => MaintenanceCountModel.fromMap(data))
            .toList();
      },
      fallback: <MaintenanceCountModel>[],
      context: 'Fetching maintenance counts',
    );
  }

  /// Delete maintenance count record
  Future<bool> deleteMaintenanceCount(String maintenanceCountId) async {
    return await safeDbCall(
      () async {
        final userId = requireAuthenticatedUser();

        await deleteFrom('maintenance_counts')
            .eq('id', maintenanceCountId)
            .eq('supervisor_id', userId);

        return true;
      },
      fallback: false,
      context: 'Deleting maintenance count',
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
            '📸 Maintenance upload progress: $completed/$total photos - Section: $currentSection');
      },
    );
  }

  /// Save photo records to separate table - OPTIMIZED
  Future<void> _savePhotoRecords(
    String maintenanceCountId,
    Map<String, List<String>> sectionPhotos,
  ) async {
    if (sectionPhotos.isEmpty) return;

    // Create all photo records
    final photoRecords = UploadOptimizer.createPhotoRecords(
      maintenanceCountId,
      'maintenance_count_id',
      sectionPhotos,
      includeOrder: true, // Maintenance counts need photo order
    );

    // Batch insert for better performance
    await UploadOptimizer.batchInsertPhotoRecords(
      photoRecords,
      (record) async {
        await insertInto('maintenance_count_photos', record);
      },
    );
  }

  /// Quick method to assign a test school to current supervisor (for testing)
  Future<void> createTestAssignment() async {
    try {
      final userId = requireAuthenticatedUser();
      print('🔍 DEBUG: Creating test assignment for user: $userId');

      // First, get any school from the database
      final schools = await client.from('schools').select('id, name').limit(1);

      if (schools.isNotEmpty) {
        final schoolId = schools.first['id'] as String;
        final schoolName = schools.first['name'] as String;

        print('🔍 DEBUG: Found school to assign: $schoolName ($schoolId)');

        // Create assignment
        await client.from('supervisor_schools').insert({
          'supervisor_id': userId,
          'school_id': schoolId,
          'assigned_at': DateTime.now().toIso8601String(),
        });

        print('🔍 DEBUG: Test assignment created successfully');
      } else {
        print('🔍 DEBUG: No schools found in database to assign');
      }
    } catch (e) {
      print('🔍 DEBUG: Error creating test assignment: $e');
    }
  }

  /// Create test schools and assignments for development
  Future<void> createTestData() async {
    try {
      final userId = requireAuthenticatedUser();
      print('🔍 DEBUG: Creating test data for user: $userId');

      // Create test schools
      final testSchools = [
        {
          'name': 'مدرسة الملك عبدالعزيز الابتدائية',
          'address': 'حي النهضة، الرياض'
        },
        {
          'name': 'مدرسة الأمير محمد بن سلمان المتوسطة',
          'address': 'حي العليا، الرياض'
        },
        {'name': 'مدرسة الملك فهد الثانوية', 'address': 'حي المعذر، الرياض'},
      ];

      final createdSchools = <Map<String, dynamic>>[];

      for (final school in testSchools) {
        final response = await client.from('schools').insert({
          'name': school['name'],
          'address': school['address'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select();

        if (response.isNotEmpty) {
          createdSchools.add(response.first);
          print('🔍 DEBUG: Created school: ${school['name']}');
        }
      }

      // Create assignments for the created schools
      for (final school in createdSchools) {
        await client.from('supervisor_schools').insert({
          'supervisor_id': userId,
          'school_id': school['id'],
          'assigned_at': DateTime.now().toIso8601String(),
        });
        print('🔍 DEBUG: Assigned school: ${school['name']}');
      }

      print(
          '🔍 DEBUG: Test data creation completed. Created ${createdSchools.length} schools and assignments.');
    } catch (e) {
      print('🔍 DEBUG: Error creating test data: $e');
    }
  }

  /// Fetch schools with maintenance reports (original functionality)
  Future<List<School>> getSchoolsWithMaintenanceReports() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();
        print(
            '🔍 DEBUG: Fetching schools with maintenance reports for user: $userId');

        // Get schools that have maintenance reports for this supervisor
        final response = await client
            .from('maintenance_reports')
            .select('school_id, schools(id, name, address)')
            .eq('supervisor_id', userId)
            .order('schools(name)', ascending: true);

        print('🔍 DEBUG: Maintenance reports query response: $response');

        // Extract unique schools from maintenance reports
        final schoolsMap = <String, School>{};

        for (final report in response) {
          final schoolData = report['schools'];
          if (schoolData != null) {
            final schoolId = schoolData['id'] as String;
            if (!schoolsMap.containsKey(schoolId)) {
              schoolsMap[schoolId] = School(
                id: schoolId,
                name: schoolData['name'] as String,
                address: schoolData['address'] as String? ?? '',
                reportsCount: 0,
                hasEmergencyReports: false,
              );
            }
          }
        }

        final schools = schoolsMap.values.toList();
        print(
            '🔍 DEBUG: Found ${schools.length} schools with maintenance reports');
        return schools;
      },
      fallback: _getMockSchools(),
      context: 'Fetching schools with maintenance reports',
    );
  }

  /// Fetch manually assigned schools (from supervisor_schools table but not in maintenance_reports)
  Future<List<School>> getManuallyAssignedSchools() async {
    return await safeNetworkDbCall(
      () async {
        final userId = requireAuthenticatedUser();
        print('🔍 DEBUG: Fetching manually assigned schools for user: $userId');

        // Get all assigned school IDs
        final assignmentResponse = await client
            .from('supervisor_schools')
            .select('school_id')
            .eq('supervisor_id', userId);

        final assignedSchoolIds = assignmentResponse
            .map((assignment) => assignment['school_id'] as String)
            .toList();

        if (assignedSchoolIds.isEmpty) {
          print('🔍 DEBUG: No assigned schools found');
          return <School>[];
        }

        // Get school IDs that have maintenance reports
        final reportsResponse = await client
            .from('maintenance_reports')
            .select('school_id')
            .eq('supervisor_id', userId)
            .inFilter('school_id', assignedSchoolIds);

        final schoolsWithReports = reportsResponse
            .map((report) => report['school_id'] as String)
            .toSet();

        // Filter to get only manually assigned schools (no maintenance reports)
        final manuallyAssignedIds = assignedSchoolIds
            .where((schoolId) => !schoolsWithReports.contains(schoolId))
            .toList();

        if (manuallyAssignedIds.isEmpty) {
          print('🔍 DEBUG: No manually assigned schools found');
          return <School>[];
        }

        // Get school details for manually assigned schools
        final schoolsResponse = await client
            .from('schools')
            .select('id, name, address')
            .inFilter('id', manuallyAssignedIds)
            .order('name', ascending: true);

        final schools = schoolsResponse.map<School>((data) {
          return School(
            id: data['id'] as String,
            name: data['name'] as String,
            address: data['address'] as String? ?? '',
            reportsCount: 0,
            hasEmergencyReports: false,
          );
        }).toList();

        print('🔍 DEBUG: Found ${schools.length} manually assigned schools');
        return schools;
      },
      fallback: <School>[],
      context: 'Fetching manually assigned schools',
    );
  }

  /// Fetch schools with maintenance reports (original functionality) - DEPRECATED
  /// Use getSchoolsWithMaintenanceReports() instead
  @deprecated

  // Mock data for fallback
  List<School> _getMockSchools() {
    return List.generate(
      8,
      (index) => School(
        id: 'maintenance-school-${index + 1}',
        name: 'مدرسة الصيانة ${index + 1}',
        address: 'منطقة ${(index % 4) + 1} - مبنى ${(index % 3) + 1}',
        reportsCount: 0,
        hasEmergencyReports: false,
      ),
    );
  }
}
