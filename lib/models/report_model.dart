import 'package:equatable/equatable.dart';

class Report extends Equatable {
  final String id;
  final String schoolName;
  final String description;
  final String type;
  final String priority;
  final List<String> images;
  final String status;
  final String supervisorId;
  final String supervisorName;
  final DateTime createdAt;
  final DateTime scheduledDate;
  final List<String> completionPhotos;
  final String? completionNote;
  final DateTime? closedAt;
  final DateTime? updatedAt;

  const Report({
    required this.id,
    required this.schoolName,
    required this.description,
    required this.type,
    required this.priority,
    required this.images,
    required this.status,
    required this.supervisorId,
    required this.supervisorName,
    required this.createdAt,
    required this.scheduledDate,
    required this.completionPhotos,
    this.completionNote,
    this.closedAt,
    this.updatedAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      schoolName: map['school_name'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      priority: map['priority'] as String,
      images: List<String>.from(map['images'] ?? []),
      status: map['status'] as String,
      supervisorId: map['supervisor_id'] as String,
      supervisorName: map['supervisors']?['username'] ?? 'غير معروف',
      createdAt: DateTime.parse(map['created_at']),
      scheduledDate: DateTime.parse(map['scheduled_date']),
      completionPhotos: List<String>.from(map['completion_photos'] ?? []),
      completionNote: map['completion_note'],
      closedAt:
          map['closed_at'] != null ? DateTime.parse(map['closed_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_name': schoolName,
      'description': description,
      'type': type,
      'priority': priority,
      'images': images,
      'status': status,
      'supervisor_id': supervisorId,
      'supervisor_name': supervisorName,
      'created_at': createdAt.toIso8601String(),
      'scheduled_date': scheduledDate.toIso8601String(),
      'completion_photos': completionPhotos,
      'completion_note': completionNote,
      'closed_at': closedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolName,
        description,
        type,
        priority,
        images,
        status,
        supervisorId,
        supervisorName,
        createdAt,
        scheduledDate,
        completionPhotos,
        completionNote,
        closedAt,
        updatedAt,
      ];
}
