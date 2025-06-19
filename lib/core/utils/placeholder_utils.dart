import '../../models/report_model.dart';

/// Utility class for safely managing placeholder data
class PlaceholderUtils {
  PlaceholderUtils._(); // Private constructor to prevent instantiation

  /// Creates placeholder reports for skeleton loading ONLY
  /// This should only be called when isLoading is true and reports list is empty
  static List<Report> createPlaceholderReports({
    required bool isLoading,
    required bool hasRealData,
    int count = 6,
  }) {
    // Safety check: Only return placeholders if we're loading and have no real data
    if (!isLoading || hasRealData) {
      return [];
    }

    final placeholders = <Report>[];
    final now = DateTime.now();

    // Create placeholder data with 3 date categories and 2 schools per category
    // Today
    placeholders.addAll([
      _createPlaceholderReport('1', 'مدرسة الأمل', now, 'Normal'),
      _createPlaceholderReport('2', 'مدرسة الأمل', now, 'Normal'),
      _createPlaceholderReport('3', 'مدرسة النور', now, 'Emergency'),
    ]);

    // Tomorrow
    placeholders.addAll([
      _createPlaceholderReport(
          '4', 'مدرسة المستقبل', now.add(const Duration(days: 1)), 'Normal'),
      _createPlaceholderReport(
          '5', 'مدرسة الرواد', now.add(const Duration(days: 1)), 'Emergency'),
    ]);

    // After tomorrow
    placeholders.add(
      _createPlaceholderReport(
          '6', 'مدرسة الإبداع', now.add(const Duration(days: 2)), 'Normal'),
    );

    return placeholders.take(count).toList();
  }

  /// Helper method to create a single placeholder report
  static Report _createPlaceholderReport(
    String id,
    String schoolName,
    DateTime scheduledDate,
    String priority,
  ) {
    return Report(
      id: id,
      schoolName: schoolName,
      scheduledDate: scheduledDate,
      priority: priority,
      status: 'pending',
      description: 'وصف البلاغ',
      type: 'صيانة',
      images: const [],
      supervisorId: '1',
      supervisorName: 'المشرف',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      completionPhotos: const [],
    );
  }

  /// Validates whether placeholder data should be used
  static bool shouldUsePlaceholders({
    required bool isLoading,
    required List<Report> reports,
  }) {
    return isLoading && reports.isEmpty;
  }
}
