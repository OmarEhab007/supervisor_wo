import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Model representing damage count items for a school
class DamageCountModel extends Equatable {
  final String id;
  final String schoolId;
  final String schoolName;
  final Map<String, int> itemCounts; // Only numeric counts needed
  final Map<String, List<String>> sectionPhotos; // Photos by section
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String supervisorId;
  final String status; // 'draft', 'submitted'

  const DamageCountModel({
    required this.id,
    required this.schoolId,
    required this.schoolName,
    required this.itemCounts,
    this.sectionPhotos = const {},
    required this.createdAt,
    this.updatedAt,
    required this.supervisorId,
    this.status = 'draft',
  });

  factory DamageCountModel.fromMap(Map<String, dynamic> map) {
    return DamageCountModel(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      schoolName: map['school_name'] as String,
      itemCounts: Map<String, int>.from(map['item_counts'] ?? {}),
      sectionPhotos: Map<String, List<String>>.from(
        (map['section_photos'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, List<String>.from(value ?? [])),
            ) ??
            {},
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      supervisorId: map['supervisor_id'] as String,
      status: map['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'school_name': schoolName,
      'item_counts': itemCounts,
      'section_photos': sectionPhotos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'supervisor_id': supervisorId,
      'status': status,
    };
  }

  DamageCountModel copyWith({
    String? id,
    String? schoolId,
    String? schoolName,
    Map<String, int>? itemCounts,
    Map<String, List<String>>? sectionPhotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supervisorId,
    String? status,
  }) {
    return DamageCountModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      itemCounts: itemCounts ?? this.itemCounts,
      sectionPhotos: sectionPhotos ?? this.sectionPhotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supervisorId: supervisorId ?? this.supervisorId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        schoolName,
        itemCounts,
        sectionPhotos,
        createdAt,
        updatedAt,
        supervisorId,
        status,
      ];
}

/// Damage count categories and items based on the provided Excel data
class DamageCategories {
  // أعمال الميكانيك والسباكة (Mechanical and Plumbing Work)
  static const Map<String, String> mechanicalPlumbingItems = {
    'plastic_chair': 'كرسي شرقي',
    'plastic_chair_external': 'كرسي افرنجي',
    'water_sink': 'حوض مغسلة مع القاعدة',
    'hidden_boxes': 'صناديق طرد مخفي-للكرسي العربي',
    'low_boxes': 'صناديق طرد واطي-للكرسي الافرنجي',
    'upvc_pipes_4_5':
        'مواسير قطر من(4 الى 0.5) بوصة upvc class 5 وضغط داخلي 16pin',
    'glass_fiber_tank_5000': 'خزان علوي فايبر جلاس سعة 5000 لتر',
    'glass_fiber_tank_4000': 'خزان علوي فايبر جلاس سعة 4000 لتر',
    'glass_fiber_tank_3000': 'خزان علوي فايبر جلاس سعة 3000 لتر',
    'booster_pump_3_phase': 'مضخات مياة 3 حصان- Booster Pump',
    'elevator_pulley_machine': 'محرك  + صندوق تروس مصاعد - Elevators',
  };

  // أعمال الكهرباء (Electrical Work)
  static const Map<String, String> electricalItems = {
    'circuit_breaker_250': 'قاطع كهرباني سعة (250) أمبير',
    'circuit_breaker_400': 'قاطع كهرباني سعة (400) أمبير',
    'circuit_breaker_1250': 'قاطع كهرباني سعة 1250 أمبير',
    'electrical_distribution_unit': 'أغطية لوحات التوزيع الفرعية',
    'copper_cable': 'كبل نحاس  مسلح مقاس (4*16)',
    'fluorescent_48w_main_branch':
        'لوحة توزيع فرعية (48) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
    'fluorescent_36w_sub_branch':
        'لوحة توزيع فرعية (36) خط مزوده عدد (24) قاطع فرعي مزدوج سعة (30 امبير) وقاطع رئيسي سعة 125 امبير',
    'electric_water_heater_50l': 'سخانات المياه الكهربائية سعة 50 لتر',
    'electric_water_heater_100l': 'سخانات المياه الكهربائية سعة 100 لتر',
  };

  // أعمال مدنية (Civil Work)
  static const Map<String, String> civilItems = {
    'upvc_50_meter': 'قماش مظلات من مادة (UPVC) لفة (50) متر مربع',
  };

  // أعمال الامن والسلامة (Safety and Security Work)
  static const Map<String, String> safetySecurityItems = {
    'pvc_pipe_connection_4':
        'محبس حريق OS&Y من قطر 4 بوصة الى 3 بوصة كامل Flange End',
    'fire_alarm_panel':
        'لوحة انذار معنونه كاملة ( مع الاكسسوارات ) والبطارية ( 12/10/8 ) زون',
    'dry_powder_6kg': 'طفاية حريق Dry powder وزن 6 كيلو',
    'co2_9kg': 'طفاية حريق CO2 وزن(9) كيلو',
    'fire_pump_1750': 'مضخة حريق 1750 دورة/د وتصرف 125 جالون/ضغط 7 بار',
    'joky_pump': 'مضخة حريق تعويضيه جوكي ضغط 7 بار',
    'fire_suppression_box': 'صدنوق إطفاء حريق بكامل عناصره',
  };

  // التكييف (Air Conditioning)
  static const Map<String, String> airConditioningItems = {
    'cabinet_ac': 'دولابي',
    'split_ac': 'سبليت',
    'window_ac': 'شباك',
    'package_ac': 'باكدج',
  };

  // Damage condition options
  static const List<String> damageConditionOptions = [
    'تالف جزئي',
    'تالف كلي',
    'يحتاج استبدال',
    'غير صالح للاستخدام',
  ];

  // All categories grouped
  static const Map<String, Map<String, String>> allCategories = {
    'mechanical_plumbing': mechanicalPlumbingItems,
    'electrical': electricalItems,
    'civil': civilItems,
    'safety_security': safetySecurityItems,
    'air_conditioning': airConditioningItems,
  };

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'mechanical_plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'civil':
        return Icons.construction_rounded;
      case 'safety_security':
        return Icons.security_rounded;
      case 'air_conditioning':
        return Icons.ac_unit_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'mechanical_plumbing':
        return const Color(0xFF3182CE); // Blue
      case 'electrical':
        return const Color(0xFFFFD700); // Gold
      case 'civil':
        return const Color(0xFF38A169); // Green
      case 'safety_security':
        return const Color(0xFFFF3F33); // Red
      case 'air_conditioning':
        return const Color(0xFF17A2B8); // Light Blue
      default:
        return const Color(0xFF718096); // Gray
    }
  }

  static String getCategoryName(String category) {
    switch (category) {
      case 'mechanical_plumbing':
        return 'أعمال الميكانيك والسباكة';
      case 'electrical':
        return 'أعمال الكهرباء';
      case 'civil':
        return 'أعمال مدنية';
      case 'safety_security':
        return 'أعمال الامن والسلامة';
      case 'air_conditioning':
        return 'التكييف';
      default:
        return 'فئة غير محددة';
    }
  }
}
