import 'package:supervisor_wo/models/report_model.dart';

/// Extension methods for the Report model to provide backward compatibility
/// with UI components that expect the old Report model structure
extension ReportExtensions on Report {
  /// Get a formatted title for display in UI
  String get title => '#${id.split('-').last}';
  
  /// Get a formatted date for display in UI
  String get date => createdAt.toString().substring(0, 10);
  
  /// Get a formatted location for display in UI
  String get location => schoolName;
  
  /// Get findings as a list of strings
  List<String> get findings {
    final result = <String>[];
    
    // Add type and priority as findings
    result.add('Type: $type');
    result.add('Priority: $priority');
    
    // Add description as a finding
    if (description.isNotEmpty) {
      result.add(description);
    }
    
    // Add completion note if available
    if (completionNote != null && completionNote!.isNotEmpty) {
      result.add('Completion note: $completionNote');
    }
    
    return result;
  }
  
  /// Create a copy of this Report with the given fields replaced with new values
  Report copyWith({
    String? id,
    String? schoolName,
    String? description,
    String? type,
    String? priority,
    List<String>? images,
    String? status,
    String? supervisorId,
    String? supervisorName,
    DateTime? createdAt,
    DateTime? scheduledDate,
    List<String>? completionPhotos,
    String? completionNote,
    DateTime? closedAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      schoolName: schoolName ?? this.schoolName,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      images: images ?? this.images,
      status: status ?? this.status,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completionPhotos: completionPhotos ?? this.completionPhotos,
      completionNote: completionNote ?? this.completionNote,
      closedAt: closedAt ?? this.closedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
