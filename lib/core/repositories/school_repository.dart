import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/models/school_model.dart';

/// Repository for handling school data operations
class SchoolRepository {
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
        final hasEmergencyReports = reports.any((report) => 
          report['priority']?.toString().toLowerCase() == 'high');
          
        return School(
          id: data['id'] as String,
          name: data['name'] as String,
          location: data['location'] as String,
          reportsCount: reportsCount,
          hasEmergencyReports: hasEmergencyReports,
          contactInfo: data['contact_info'] as String? ?? '',
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
      final hasEmergencyReports = reports.any((report) => 
        report['priority']?.toString().toLowerCase() == 'high');
        
      return School(
        id: response['id'] as String,
        name: response['name'] as String,
        location: response['location'] as String,
        reportsCount: reportsCount,
        hasEmergencyReports: hasEmergencyReports,
        contactInfo: response['contact_info'] as String? ?? '',
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
        location: 'District ${(index % 5) + 1}, Building ${(index % 3) + 1}',
        reportsCount: index * 2 + 3,
        hasEmergencyReports: index % 3 == 0,
        contactInfo: 'principal@school${index + 1}.edu',
      ),
    );
  }
  
  School _getMockSchoolById(String schoolId) {
    final schoolNumber = int.parse(schoolId.split('-').last);
    
    return School(
      id: schoolId,
      name: 'School $schoolNumber',
      location: 'District ${(schoolNumber % 5) + 1}, Building ${(schoolNumber % 3) + 1}',
      reportsCount: schoolNumber * 2 + 3,
      hasEmergencyReports: schoolNumber % 3 == 0,
      contactInfo: 'principal@school$schoolNumber.edu',
    );
  }
}
