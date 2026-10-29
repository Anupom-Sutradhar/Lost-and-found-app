class AppUser {
  final String uid;
  final String email;
  final String name;
  final String studentId;
  final String? photoUrl;
  final String? department;
  final String? phone;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.studentId,
    this.photoUrl,
    this.department,
    this.phone,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['id'] as String,
      email: (map['email'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      studentId: (map['student_id'] ?? '') as String,
      photoUrl: map['photo_url'] as String?,
      department: map['department'] as String?,
      phone: map['phone'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'name': name,
      'student_id': studentId,
      'photo_url': photoUrl,
      'department': department,
      'phone': phone,
    };
  }

  AppUser copyWith({
    String? name,
    String? studentId,
    String? photoUrl,
    String? department,
    String? phone,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      photoUrl: photoUrl ?? this.photoUrl,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
