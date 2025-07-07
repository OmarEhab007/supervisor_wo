import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/models/school_model.dart';

/// Repository for handling school data operations
class SchoolRepository {
  /// Fetch schools assigned to the current supervisor with last visit dates from all sources
  Future<List<School>> getSupervisorSchools() async {
    try {
      final user = SupabaseClientWrapper.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userId = user.id;
      print('🔍 DEBUG: Fetching schools for supervisor: $userId');

      // Get assigned school IDs first
      final assignmentResponse = await SupabaseClientWrapper.client
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

      // Get all schools first
      final schoolsResponse = await SupabaseClientWrapper.client
          .from('schools')
          .select('id, name, address')
          .inFilter('id', schoolIds)
          .order('name', ascending: true);

      print('🔍 DEBUG: Found ${schoolsResponse.length} assigned schools');

      // Batch fetch all last visit dates for better performance
      final lastVisitDates = await _getBatchLastVisitDates(schoolIds, userId);

      final schools = schoolsResponse.map<School>((schoolData) {
        final schoolId = schoolData['id'] as String;
        final lastVisitInfo =
            lastVisitDates[schoolId] ?? {'date': null, 'source': null};

        return School(
          id: schoolId,
          name: schoolData['name'] as String,
          address: schoolData['address'] as String? ?? '',
          reportsCount: 0, // Will be calculated if needed
          hasEmergencyReports: false,
          lastVisitDate: lastVisitInfo['date'] as DateTime?,
          lastVisitSource: lastVisitInfo['source'] as String?,
        );
      }).toList();

      print('🔍 DEBUG: Returning ${schools.length} schools with visit dates');
      return schools;
    } catch (e) {
      print('🔍 ERROR: Failed to fetch supervisor schools: $e');
      // Fallback to mock data if Supabase fetch fails
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockSchools();
    }
  }

  /// Batch fetch last visit dates for multiple schools (optimized)
  Future<Map<String, Map<String, dynamic>>> _getBatchLastVisitDates(
      List<String> schoolIds, String supervisorId) async {
    final result = <String, Map<String, dynamic>>{};

    try {
      // Initialize all schools with null values
      for (final schoolId in schoolIds) {
        result[schoolId] = {'date': null, 'source': null};
      }

      // Create a map of school ID to school name for reports query
      final schoolsResponse = await SupabaseClientWrapper.client
          .from('schools')
          .select('id, name')
          .inFilter('id', schoolIds);

      final schoolIdToName = <String, String>{};
      for (final school in schoolsResponse) {
        schoolIdToName[school['id'] as String] = school['name'] as String;
      }

      // Batch query 1: Get all reports completion dates
      final schoolNames = schoolIdToName.values.toList();
      if (schoolNames.isNotEmpty) {
        final reportsResponse = await SupabaseClientWrapper.client
            .from('reports')
            .select('school_name, closed_at')
            .inFilter('school_name', schoolNames)
            .eq('supervisor_id', supervisorId)
            .not('closed_at', 'is', null)
            .order('closed_at', ascending: false);

        // Process reports and find latest for each school
        final schoolReports = <String, List<Map<String, dynamic>>>{};
        for (final report in reportsResponse) {
          final schoolName = report['school_name'] as String;
          final schoolId = schoolIdToName.entries
              .firstWhere((entry) => entry.value == schoolName)
              .key;

          if (!schoolReports.containsKey(schoolId)) {
            schoolReports[schoolId] = [];
          }
          schoolReports[schoolId]!.add(report);
        }

        // Get latest report for each school
        for (final entry in schoolReports.entries) {
          final schoolId = entry.key;
          final reports = entry.value;
          if (reports.isNotEmpty) {
            final latestReport =
                reports.first; // Already ordered by closed_at desc
            final closedAt =
                DateTime.parse(latestReport['closed_at'] as String);
            result[schoolId] = {'date': closedAt, 'source': 'إنجاز بلاغ'};
          }
        }
      }

      // Batch query 2: Get all maintenance counts
      final maintenanceResponse = await SupabaseClientWrapper.client
          .from('maintenance_counts')
          .select('school_id, updated_at')
          .inFilter('school_id', schoolIds)
          .eq('supervisor_id', supervisorId)
          .eq('status', 'submitted')
          .not('updated_at', 'is', null)
          .order('updated_at', ascending: false);

      // Process maintenance counts
      final schoolMaintenanceCounts = <String, List<Map<String, dynamic>>>{};
      for (final maintenance in maintenanceResponse) {
        final schoolId = maintenance['school_id'] as String;
        if (!schoolMaintenanceCounts.containsKey(schoolId)) {
          schoolMaintenanceCounts[schoolId] = [];
        }
        schoolMaintenanceCounts[schoolId]!.add(maintenance);
      }

      // Get latest maintenance count for each school and compare with existing dates
      for (final entry in schoolMaintenanceCounts.entries) {
        final schoolId = entry.key;
        final maintenanceCounts = entry.value;
        if (maintenanceCounts.isNotEmpty) {
          final latestMaintenance = maintenanceCounts.first;
          final updatedAt =
              DateTime.parse(latestMaintenance['updated_at'] as String);

          final currentDate = result[schoolId]!['date'] as DateTime?;
          if (currentDate == null || updatedAt.isAfter(currentDate)) {
            result[schoolId] = {'date': updatedAt, 'source': 'حصر الاعداد'};
          }
        }
      }

      // Batch query 3: Get all damage counts
      final damageResponse = await SupabaseClientWrapper.client
          .from('damage_counts')
          .select('school_id, updated_at')
          .inFilter('school_id', schoolIds)
          .eq('supervisor_id', supervisorId)
          .eq('status', 'submitted')
          .not('updated_at', 'is', null)
          .order('updated_at', ascending: false);

      // Process damage counts
      final schoolDamageCounts = <String, List<Map<String, dynamic>>>{};
      for (final damage in damageResponse) {
        final schoolId = damage['school_id'] as String;
        if (!schoolDamageCounts.containsKey(schoolId)) {
          schoolDamageCounts[schoolId] = [];
        }
        schoolDamageCounts[schoolId]!.add(damage);
      }

      // Get latest damage count for each school and compare with existing dates
      for (final entry in schoolDamageCounts.entries) {
        final schoolId = entry.key;
        final damageCounts = entry.value;
        if (damageCounts.isNotEmpty) {
          final latestDamage = damageCounts.first;
          final updatedAt =
              DateTime.parse(latestDamage['updated_at'] as String);

          final currentDate = result[schoolId]!['date'] as DateTime?;
          if (currentDate == null || updatedAt.isAfter(currentDate)) {
            result[schoolId] = {'date': updatedAt, 'source': 'حصر التوالف'};
          }
        }
      }

      // 4. Get latest achievement submissions for all schools
      final achievementsResponse = await SupabaseClientWrapper.client
          .from('school_achievements')
          .select('school_id, submitted_at, achievement_type')
          .eq('supervisor_id', supervisorId)
          .eq('status', 'submitted')
          .inFilter('school_id', schoolIds)
          .not('submitted_at', 'is', null)
          .order('submitted_at', ascending: false);

      // Group achievements by school and get the latest for each school
      final schoolAchievements = <String, List<Map<String, dynamic>>>{};
      for (final achievement in achievementsResponse) {
        final schoolId = achievement['school_id'] as String;
        if (!schoolAchievements.containsKey(schoolId)) {
          schoolAchievements[schoolId] = [];
        }
        schoolAchievements[schoolId]!.add(achievement);
      }

      // Get latest achievement for each school and compare with existing dates
      for (final entry in schoolAchievements.entries) {
        final schoolId = entry.key;
        final achievements = entry.value;
        if (achievements.isNotEmpty) {
          final latestAchievement = achievements.first;
          final submittedAt =
              DateTime.parse(latestAchievement['submitted_at'] as String);
          final achievementType =
              latestAchievement['achievement_type'] as String;

          // Map achievement type to Arabic source name
          String sourceName;
          switch (achievementType) {
            case 'maintenance_achievement':
              sourceName = 'مشهد صيانة';
              break;
            case 'ac_achievement':
              sourceName = 'مشهد تكييف';
              break;
            case 'checklist':
              sourceName = 'تشيك ليست';
              break;
            default:
              sourceName = 'إنجاز';
          }

          final currentDate = result[schoolId]!['date'] as DateTime?;
          if (currentDate == null || submittedAt.isAfter(currentDate)) {
            result[schoolId] = {'date': submittedAt, 'source': sourceName};
          }
        }
      }

      return result;
    } catch (e) {
      print('Error getting batch last visit dates: $e');
      // Return empty results for all schools
      for (final schoolId in schoolIds) {
        result[schoolId] = {'date': null, 'source': null};
      }
      return result;
    }
  }

  /// Get the most recent visit date from all sources (reports, maintenance counts, damage counts)
  Future<Map<String, dynamic>> _getLastVisitDateForSchool(
      String schoolId, String supervisorId) async {
    final List<Map<String, dynamic>> allDates = [];

    try {
      // 1. Get latest report completion date
      // First get the school name from school ID
      final schoolResponse = await SupabaseClientWrapper.client
          .from('schools')
          .select('name')
          .eq('id', schoolId)
          .single();

      final schoolName = schoolResponse['name'] as String;

      final reportsResponse = await SupabaseClientWrapper.client
          .from('reports')
          .select('closed_at')
          .eq('school_name', schoolName)
          .eq('supervisor_id', supervisorId)
          .not('closed_at', 'is', null)
          .order('closed_at', ascending: false)
          .limit(1);

      if (reportsResponse.isNotEmpty) {
        final closedAt = reportsResponse.first['closed_at'] as String;
        allDates.add({
          'date': DateTime.parse(closedAt),
          'source': 'إنجاز بلاغ',
        });
      }

      // 2. Get latest maintenance count submission date
      final maintenanceResponse = await SupabaseClientWrapper.client
          .from('maintenance_counts')
          .select('updated_at')
          .eq('school_id', schoolId)
          .eq('supervisor_id', supervisorId)
          .eq('status', 'submitted')
          .not('updated_at', 'is', null)
          .order('updated_at', ascending: false)
          .limit(1);

      if (maintenanceResponse.isNotEmpty) {
        final updatedAt = maintenanceResponse.first['updated_at'] as String;
        allDates.add({
          'date': DateTime.parse(updatedAt),
          'source': 'حصر الاعداد',
        });
      }

      // 3. Get latest damage count submission date
      final damageResponse = await SupabaseClientWrapper.client
          .from('damage_counts')
          .select('updated_at')
          .eq('school_id', schoolId)
          .eq('supervisor_id', supervisorId)
          .eq('status', 'submitted')
          .not('updated_at', 'is', null)
          .order('updated_at', ascending: false)
          .limit(1);

      if (damageResponse.isNotEmpty) {
        final updatedAt = damageResponse.first['updated_at'] as String;
        allDates.add({
          'date': DateTime.parse(updatedAt),
          'source': 'حصر التوالف',
        });
      }

      // Find the most recent date
      if (allDates.isNotEmpty) {
        allDates.sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        return allDates.first;
      }

      return {'date': null, 'source': null};
    } catch (e) {
      print('Error getting last visit date for school $schoolId: $e');
      return {'date': null, 'source': null};
    }
  }

  /// Fetch all schools
  Future<List<School>> getSchools() async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('schools')
          .select('*, reports:reports(*)')
          .order('name', ascending: true);

      return response.map<School>((data) {
        // Count reports and check for emergency reports
        final reports = (data['reports'] as List?) ?? [];
        final reportsCount = reports.length;
        final hasEmergencyReports = reports.any(
            (report) => report['priority']?.toString().toLowerCase() == 'high');

        return School(
          id: data['id'] as String,
          name: data['name'] as String,
          address: data['address'] as String? ?? '',
          reportsCount: reportsCount,
          hasEmergencyReports: hasEmergencyReports,
        );
      }).toList();
    } catch (e) {
      // Fallback to mock data if Supabase fetch fails
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockSchools();
    }
  }

  /// Fetch a specific school by ID
  Future<School> getSchoolById(String schoolId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('schools')
          .select('*, reports:reports(*)')
          .eq('id', schoolId)
          .single();

      // Count reports and check for emergency reports
      final reports = (response['reports'] as List?) ?? [];
      final reportsCount = reports.length;
      final hasEmergencyReports = reports.any(
          (report) => report['priority']?.toString().toLowerCase() == 'high');

      return School(
        id: response['id'] as String,
        name: response['name'] as String,
        address: response['address'] as String? ?? '',
        reportsCount: reportsCount,
        hasEmergencyReports: hasEmergencyReports,
      );
    } catch (e) {
      // Fallback to mock data if Supabase fetch fails
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockSchoolById(schoolId);
    }
  }

  // Helper methods for mock data (fallback)

  List<School> _getMockSchools() {
    return List.generate(
      10,
      (index) => School(
        id: 'school-${index + 1}',
        name: 'School ${index + 1}',
        address: 'District ${(index % 5) + 1}, Building ${(index % 3) + 1}',
        reportsCount: index * 2 + 3,
        hasEmergencyReports: index % 3 == 0,
        lastVisitDate: index % 2 == 0
            ? DateTime.now().subtract(Duration(days: index + 1))
            : null,
        lastVisitSource: index % 2 == 0
            ? (index % 3 == 0 ? 'إنجاز بلاغ' : 'حصر الاعداد')
            : null,
      ),
    );
  }

  School _getMockSchoolById(String schoolId) {
    final schoolNumber = int.parse(schoolId.split('-').last);

    return School(
      id: schoolId,
      name: 'School $schoolNumber',
      address:
          'District ${(schoolNumber % 5) + 1}, Building ${(schoolNumber % 3) + 1}',
      reportsCount: schoolNumber * 2 + 3,
      hasEmergencyReports: schoolNumber % 3 == 0,
      lastVisitDate: schoolNumber % 2 == 0
          ? DateTime.now().subtract(Duration(days: schoolNumber + 1))
          : null,
      lastVisitSource: schoolNumber % 2 == 0
          ? (schoolNumber % 3 == 0 ? 'إنجاز بلاغ' : 'حصر الاعداد')
          : null,
    );
  }
}
