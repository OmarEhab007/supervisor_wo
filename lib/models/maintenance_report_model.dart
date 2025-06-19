import 'package:equatable/equatable.dart';

class MaintenanceReport extends Equatable {
  final String id;
  final String supervisorId;
  final String schoolId;
  final String description;
  final String status;
  final String? priority;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? closedAt;
  final List<String> completionPhotos;
  final String? completionNote;

  const MaintenanceReport({
    required this.id,
    required this.supervisorId,
    required this.schoolId,
    required this.description,
    required this.status,
    this.priority,
    required this.images,
    required this.createdAt,
    this.closedAt,
    required this.completionPhotos,
    this.completionNote,
  });

  factory MaintenanceReport.fromMap(Map<String, dynamic> map) {
    return MaintenanceReport(
      id: map['id'] as String,
      supervisorId: map['supervisor_id'] as String,
      schoolId: map['school_name'] as String,
      description: map['description'] as String,
      status: map['status'] as String,
      images: List<String>.from(map['images'] ?? []),
      createdAt: DateTime.parse(map['created_at']),
      closedAt:
          map['closed_at'] != null ? DateTime.parse(map['closed_at']) : null,
      completionPhotos: List<String>.from(map['completion_photos'] ?? []),
      completionNote: map['completion_note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisor_id': supervisorId,
      'school_name': schoolId,
      'description': description,
      'status': status,
      'priority': priority,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'completion_photos': completionPhotos,
      'completion_note': completionNote,
    };
  }

  @override
  List<Object?> get props => [
        id,
        supervisorId,
        schoolId,
        description,
        status,
        priority,
        images,
        createdAt,
        closedAt,
        completionPhotos,
        completionNote,
      ];
}
