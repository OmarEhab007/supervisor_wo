import 'package:equatable/equatable.dart';

/// Model representing a school
class School extends Equatable {
  /// Unique identifier for the school
  final String id;
  
  /// Name of the school
  final String name;
  
  /// Location of the school
  final String location;
  
  /// Number of reports associated with this school
  final int reportsCount;
  
  /// Whether this school has any emergency reports
  final bool hasEmergencyReports;
  
  /// Contact information for the school
  final String contactInfo;
  
  /// Creates a new School instance
  const School({
    required this.id,
    required this.name,
    required this.location,
    required this.reportsCount,
    this.hasEmergencyReports = false,
    this.contactInfo = '',
  });
  
  /// Creates a School from a map (JSON)
  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      reportsCount: map['reports_count'] as int,
      hasEmergencyReports: map['has_emergency_reports'] as bool? ?? false,
      contactInfo: map['contact_info'] as String? ?? '',
    );
  }
  
  /// Converts the School to a map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'reports_count': reportsCount,
      'has_emergency_reports': hasEmergencyReports,
      'contact_info': contactInfo,
    };
  }
  
  /// Creates a copy of this School with the given fields replaced with new values
  School copyWith({
    String? id,
    String? name,
    String? location,
    int? reportsCount,
    bool? hasEmergencyReports,
    String? contactInfo,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      reportsCount: reportsCount ?? this.reportsCount,
      hasEmergencyReports: hasEmergencyReports ?? this.hasEmergencyReports,
      contactInfo: contactInfo ?? this.contactInfo,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    name,
    location,
    reportsCount,
    hasEmergencyReports,
    contactInfo,
  ];
}
