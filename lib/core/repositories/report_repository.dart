import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supervisor_wo/core/repositories/base_repository.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/models/maintenance_report_model.dart';
import 'package:supervisor_wo/models/report_model.dart';
import 'package:supervisor_wo/models/user_profile.dart';

/// Repository for handling report data operations
class ReportRepository extends BaseRepository {
  /// Update a report's status in the database
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      await SupabaseClientWrapper.client
          .from('reports')
          .update({'status': status}).eq('id', reportId);
      return true;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }

  /// Complete a report with completion note and photos
  Future<bool> completeReport({
    required String reportId,
    required String completionNote,
    required List<String> completionPhotos,
  }) async {
    try {
      // First check the current status to determine if it should be 'completed' or 'late_completed'
      final response = await SupabaseClientWrapper.client
          .from('reports')
          .select('status')
          .eq('id', reportId)
          .single();

      final currentStatus = response['status'] as String;
      final newStatus =
          currentStatus == 'late' ? 'late_completed' : 'completed';

      // Update the report with completion details
      await SupabaseClientWrapper.client.from('reports').update({
        'status': newStatus,
        'completion_note': completionNote,
        'completion_photos': completionPhotos,
        'closed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);

      return true;
    } catch (e) {
      print('Error completing report: $e');
      return false;
    }
  }

  Future<bool> completeMaintenanceReport({
    required String reportId,
    required String completionNote,
    required List<String> completionPhotos,
  }) async {
    try {
      print('========================================');
      print('REPOSITORY: Starting completeMaintenanceReport');
      print('Report ID: $reportId');
      print('Completion note length: ${completionNote.length}');
      print('Completion note: $completionNote');
      print('Photos count: ${completionPhotos.length}');
      print('Photos: $completionPhotos');
      print('========================================');

      // Check current status
      print('REPOSITORY: Checking current status...');
      final response = await SupabaseClientWrapper.client
          .from('maintenance_reports')
          .select('status')
          .eq('id', reportId)
          .single();

      print('REPOSITORY: Current report data: $response');
      final currentStatus = response['status'] as String;
      final newStatus =
          currentStatus == 'late' ? 'late_completed' : 'completed';

      print(
          'REPOSITORY: Updating status from "$currentStatus" to "$newStatus"');

      final updateData = {
        'status': newStatus,
        'completion_note': completionNote,
        'completion_photos': completionPhotos,
        'closed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('REPOSITORY: Update data prepared:');
      print('  - status: ${updateData['status']}');
      print('  - completion_note: ${updateData['completion_note']}');
      print(
          '  - completion_photos length: ${(updateData['completion_photos'] as List).length}');
      print('  - closed_at: ${updateData['closed_at']}');
      print('  - updated_at: ${updateData['updated_at']}');

      print('REPOSITORY: Executing Supabase update...');

      final updateResult = await SupabaseClientWrapper.client
          .from('maintenance_reports')
          .update(updateData)
          .eq('id', reportId);

      print('REPOSITORY: Update result: $updateResult');
      print('REPOSITORY: Maintenance report completed successfully');
      print('========================================');
      return true;
    } catch (e) {
      print('========================================');
      print('REPOSITORY ERROR: Exception in completeMaintenanceReport');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

      // Try to get more specific error info if it's a Supabase error
      if (e.toString().contains('PostgrestException') ||
          e.toString().contains('AuthException')) {
        print('REPOSITORY ERROR: This appears to be a Supabase-specific error');
        print('Full error details: $e');
      }

      print('========================================');
      return false;
    }
  }

  /// Fetch all reports for the current supervisor
  Future<List<Report>> getReports() async {
    return await safeNetworkDbCall(
      () async {
        // Get current user ID
        final currentUser = SupabaseClientWrapper.client.auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        final response = await SupabaseClientWrapper.client
            .from('reports')
            .select('*, supervisors:supervisor_id(*)')
            .eq('supervisor_id', currentUser.id) // Filter by current user ID
            .order('created_at', ascending: false);

        return response.map<Report>((data) => Report.fromMap(data)).toList();
      },
      fallback: _getMockReports(),
      context: 'Fetching reports',
    );
  }

  /// Fetch a specific report by ID
  Future<Report> getReportById(String reportId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('reports')
          .select('*, supervisors:supervisor_id(*)')
          .eq('id', reportId)
          .single();

      return Report.fromMap(response);
    } catch (e) {
      // Fallback to mock data if Supabase fetch fails
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockReportById(reportId);
    }
  }

  /// Fetch all maintenance reports for the current supervisor
  Future<List<MaintenanceReport>> getMaintenanceReports(
      {String? status}) async {
    try {
      // Get current user ID
      final currentUser = SupabaseClientWrapper.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = SupabaseClientWrapper.client
          .from('maintenance_reports')
          .select()
          .eq('supervisor_id', currentUser.id); // Filter by current user ID

      // Add status filter if provided
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return response
          .map<MaintenanceReport>((data) => MaintenanceReport.fromMap(data))
          .toList();
    } catch (e) {
      // Fallback to mock data if Supabase fetch fails
      await Future.delayed(const Duration(milliseconds: 800));
      return _getMockMaintenanceReports();
    }
  }

  /// Fetch a specific maintenance report by ID
  Future<MaintenanceReport> getMaintenanceReportById(String reportId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('maintenance_reports')
          .select()
          .eq('id', reportId)
          .single();

      return MaintenanceReport.fromMap(response);
    } catch (e) {
      // Fallback to mock data if Supabase fetch fails
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockMaintenanceReportById(reportId);
    }
  }

  /// Fetch user profile by ID
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await SupabaseClientWrapper.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      print('Fetched profile from Supabase: $response');
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching user profile from Supabase: $e');
      // Don't fall back to mock data, throw the error so it can be handled properly
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Update user profile in the `supervisors` table
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    // Build the payload – include only columns that can change
    final data = <String, dynamic>{
      'username': profile.username,
      'email'   : profile.email,
      'phone'   : profile.phone,
      if (profile.plateNumbers        != null) 'plate_numbers'        : profile.plateNumbers,
      if (profile.plateEnglishLetters != null) 'plate_english_letters': profile.plateEnglishLetters,
      if (profile.plateArabicLetters  != null) 'plate_arabic_letters' : profile.plateArabicLetters,
      if (profile.iqamaId             != null) 'iqama_id'             : profile.iqamaId,
      if (profile.workId              != null) 'work_id'              : profile.workId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      // Update without expecting a return value to avoid potential trigger issues
      await SupabaseClientWrapper.client
          .from('supervisors')
          .update(data)
          .eq('id', profile.id);

      // Fetch the updated profile separately to ensure we get the latest data
      final updatedRow = await SupabaseClientWrapper.client
          .from('supervisors')
          .select()
          .eq('id', profile.id)
          .single();

      if (updatedRow == null) {
        throw Exception('Profile not found after update');
      }

      // Cache locally for faster subsequent loads
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_profile_${profile.id}',
        jsonEncode(updatedRow),
      );

      return UserProfile.fromJson(updatedRow);
    } on PostgrestException catch (e, s) {
      debugPrint('Supabase update failed: $e\n$s');
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e, s) {
      debugPrint('Unexpected error updating profile: $e\n$s');
      // If update fails, return the profile with updated timestamp for local use
      return profile.copyWith(updatedAt: DateTime.now());
    }
  }

  /// Get current user profile
  Future<UserProfile> getCurrentUserProfile() async {
    // Debug flag to print detailed information
    const bool debug = true;

    void debugLog(String message) {
      if (debug) {
        print('[ReportRepository:getCurrentUserProfile] $message');
      }
    }

    final currentUser = SupabaseClientWrapper.client.auth.currentUser;
    if (currentUser != null) {
      debugLog('Current user found: ${currentUser.id}');
      
      // Try to get profile from supervisors table first
      try {
        debugLog('Attempting to fetch from supervisors table...');
        final response = await SupabaseClientWrapper.client
            .from('supervisors')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();

        if (response != null) {
          debugLog('Successfully retrieved profile from supervisors table: $response');
          return UserProfile.fromJson(response);
        } else {
          debugLog('No profile found in supervisors table');
        }
      } catch (e) {
        debugLog('Error fetching from supervisors table: $e');
      }

      // If no profile exists in supervisors table, create a minimal one from auth data
      debugLog('No profile found in supervisors table, creating minimal profile from auth data');
      final newProfile = UserProfile(
        id: currentUser.id,
        username: currentUser.email?.split('@').first ?? 'User',
        email: currentUser.email ?? '',
        phone: '',
        createdAt: DateTime.now(),
      );
      
      debugLog('Using minimal profile for current session');
      return newProfile;
    } else {
      debugLog('No authenticated user found, throwing exception');
      throw Exception('No authenticated user found');
    }
  }

  // Helper methods for mock data (fallback)

  List<Report> _getMockReports() {
    return List.generate(
      20,
      (index) => Report(
        id: 'report-${index + 1}',
        schoolName: 'School ${index + 1}',
        description: index % 2 == 0
            ? 'Regular inspection report for the specified location.'
            : 'Follow-up inspection report addressing previous issues.',
        type: index % 3 == 0
            ? 'Electrical'
            : (index % 2 == 0 ? 'Plumbing' : 'General'),
        priority: index % 4 == 0 ? 'High' : (index % 3 == 0 ? 'Medium' : 'Low'),
        images: ['image1.jpg', 'image2.jpg'],
        status: index % 3 == 0
            ? 'pending'
            : (index % 5 == 0 ? 'in_progress' : 'completed'),
        supervisorId: 'supervisor-1',
        supervisorName: 'John Doe',
        createdAt: DateTime.now().subtract(Duration(days: index * 2)),
        scheduledDate: DateTime.now().add(Duration(days: index)),
        completionPhotos:
            index % 3 == 0 ? [] : ['completion1.jpg', 'completion2.jpg'],
        completionNote: index % 3 == 0 ? null : 'Work completed successfully',
        closedAt: index % 3 == 0
            ? null
            : DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(hours: index * 5)),
      ),
    );
  }

  Report _getMockReportById(String reportId) {
    final reportNumber = int.parse(reportId.split('-').last);

    return Report(
      id: reportId,
      schoolName: 'School $reportNumber',
      description:
          'This is a detailed report about the inspection conducted at School $reportNumber. '
          'The inspection revealed several issues that need attention. '
          'The team has documented all findings with appropriate evidence.',
      type: reportNumber % 3 == 0
          ? 'Electrical'
          : (reportNumber % 2 == 0 ? 'Plumbing' : 'General'),
      priority: reportNumber % 4 == 0
          ? 'High'
          : (reportNumber % 3 == 0 ? 'Medium' : 'Low'),
      images: ['image1.jpg', 'image2.jpg', 'image3.jpg'],
      status: reportNumber % 3 == 0
          ? 'pending'
          : (reportNumber % 5 == 0 ? 'in_progress' : 'completed'),
      supervisorId: 'supervisor-1',
      supervisorName: 'John Doe',
      createdAt: DateTime.now().subtract(Duration(days: reportNumber * 2)),
      scheduledDate: DateTime.now().add(Duration(days: reportNumber)),
      completionPhotos:
          reportNumber % 3 == 0 ? [] : ['completion1.jpg', 'completion2.jpg'],
      completionNote: reportNumber % 3 == 0
          ? null
          : 'Work completed successfully on ${DateTime.now().toString().substring(0, 10)}',
      closedAt: reportNumber % 3 == 0
          ? null
          : DateTime.now().subtract(Duration(days: reportNumber)),
      updatedAt: DateTime.now().subtract(Duration(hours: reportNumber * 5)),
    );
  }

  List<MaintenanceReport> _getMockMaintenanceReports() {
    return List.generate(
      15,
      (index) => MaintenanceReport(
        id: 'maintenance-${index + 1}',
        supervisorId: 'supervisor-1',
        schoolId: 'school-${(index % 5) + 1}',
        description:
            'Maintenance request for ${index % 2 == 0 ? 'electrical' : 'plumbing'} issues.',
        status: index % 3 == 0
            ? 'pending'
            : (index % 4 == 0 ? 'in_progress' : 'completed'),
        images: ['image1.jpg', 'image2.jpg'],
        createdAt: DateTime.now().subtract(Duration(days: index * 2)),
        closedAt: index % 3 != 0
            ? DateTime.now().subtract(Duration(days: index))
            : null,
        completionPhotos:
            index % 3 != 0 ? ['completion1.jpg', 'completion2.jpg'] : [],
        completionNote: index % 3 != 0 ? 'Work completed successfully' : null,
      ),
    );
  }

  MaintenanceReport _getMockMaintenanceReportById(String reportId) {
    final reportNumber = int.parse(reportId.split('-').last);

    return MaintenanceReport(
      id: reportId,
      supervisorId: 'supervisor-1',
      schoolId: 'school-${(reportNumber % 5) + 1}',
      description:
          'Maintenance request for ${reportNumber % 2 == 0 ? 'electrical' : 'plumbing'} issues.',
      status: reportNumber % 3 == 0
          ? 'pending'
          : (reportNumber % 4 == 0 ? 'in_progress' : 'completed'),
      images: ['image1.jpg', 'image2.jpg'],
      createdAt: DateTime.now().subtract(Duration(days: reportNumber * 2)),
      closedAt: reportNumber % 3 != 0
          ? DateTime.now().subtract(Duration(days: reportNumber))
          : null,
      completionPhotos:
          reportNumber % 3 != 0 ? ['completion1.jpg', 'completion2.jpg'] : [],
      completionNote:
          reportNumber % 3 != 0 ? 'Work completed successfully' : null,
    );
  }
}
