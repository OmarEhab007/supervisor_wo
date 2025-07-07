import 'package:equatable/equatable.dart';

/// Model representing a school
class School extends Equatable {
  /// Unique identifier for the school
  final String id;

  /// Name of the school
  final String name;

  /// Address of the school (optional)
  final String address;

  /// Number of reports associated with this school
  final int reportsCount;

  /// Whether this school has any emergency reports
  final bool hasEmergencyReports;

  /// Last visit date (completion date of the last report)
  final DateTime? lastVisitDate;
  final String? lastVisitSource; // Source of the last visit date

  /// Creates a new School instance
  const School({
    required this.id,
    required this.name,
    this.address = '',
    required this.reportsCount,
    this.hasEmergencyReports = false,
    this.lastVisitDate,
    this.lastVisitSource,
  });

  /// Creates a School from a map (JSON)
  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String? ?? '',
      reportsCount: map['reports_count'] as int? ?? 0,
      hasEmergencyReports: map['has_emergency_reports'] as bool? ?? false,
      lastVisitDate: map['last_visit_date'] != null
          ? DateTime.parse(map['last_visit_date'] as String)
          : null,
      lastVisitSource: map['last_visit_source'] as String?,
    );
  }

  /// Converts the School to a map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'reports_count': reportsCount,
      'has_emergency_reports': hasEmergencyReports,
      'last_visit_date': lastVisitDate?.toIso8601String(),
      'last_visit_source': lastVisitSource,
    };
  }

  /// Creates a copy of this School with the given fields replaced with new values
  School copyWith({
    String? id,
    String? name,
    String? address,
    int? reportsCount,
    bool? hasEmergencyReports,
    DateTime? lastVisitDate,
    String? lastVisitSource,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      reportsCount: reportsCount ?? this.reportsCount,
      hasEmergencyReports: hasEmergencyReports ?? this.hasEmergencyReports,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      lastVisitSource: lastVisitSource ?? this.lastVisitSource,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        reportsCount,
        hasEmergencyReports,
        lastVisitDate,
        lastVisitSource,
      ];
}
