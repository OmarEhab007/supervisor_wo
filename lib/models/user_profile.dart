class UserProfile {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String? plateNumbers;
  final String? plateEnglishLetters;
  final String? plateArabicLetters;
  final String? iqamaId;
  final String? workId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.plateNumbers,
    this.plateEnglishLetters,
    this.plateArabicLetters,
    this.iqamaId,
    this.workId,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      // Handle both camelCase and snake_case field names for compatibility
      plateNumbers: json['plateNumbers'] as String? ?? 
                   json['plate_numbers'] as String?,
      plateEnglishLetters: json['plateEnglishLetters'] as String? ?? 
                   json['plate_english_letters'] as String?,
      plateArabicLetters: json['plateArabicLetters'] as String? ?? 
                   json['plate_arabic_letters'] as String?,
      iqamaId: json['iqamaId'] as String? ?? 
               json['iqama_id'] as String?,
      workId: json['workId'] as String? ?? 
              json['work_id'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'plate_numbers': plateNumbers,
      'plate_english_letters': plateEnglishLetters,
      'plate_arabic_letters': plateArabicLetters,
      'iqama_id': iqamaId,
      'work_id': workId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? plateNumbers,
    String? plateEnglishLetters,
    String? plateArabicLetters,
    String? iqamaId,
    String? workId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      plateNumbers: plateNumbers ?? this.plateNumbers,
      plateEnglishLetters: plateEnglishLetters ?? this.plateEnglishLetters,
      plateArabicLetters: plateArabicLetters ?? this.plateArabicLetters,
      iqamaId: iqamaId ?? this.iqamaId,
      workId: workId ?? this.workId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
