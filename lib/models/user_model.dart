/// User Model for CampusEase
library;

class UserModel {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? profilePhoto;
  final String? mobileNum;
  final String? address;
  final DateTime? dob;
  final String? emergencyContact;
  final String? courseTaken;
  final String? classId;
  final String? department;
  final bool emailVerified;
  final bool? accountActivated;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profilePhoto,
    this.mobileNum,
    this.address,
    this.dob,
    this.emergencyContact,
    this.courseTaken,
    this.classId,
    this.department,
    this.emailVerified = false,
    this.accountActivated,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  bool get isStudent => role == 'student';
  bool get isFaculty => role == 'faculty';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? '',
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      profilePhoto: json['profile_photo'],
      mobileNum: json['mobile_num']?.toString(),
      address: json['address'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      emergencyContact: json['emergency_contact']?.toString(),
      courseTaken: json['course_taken'],
      classId: json['class_id'],
      department: json['department'],
      emailVerified: json['email_verified'] ?? false,
      accountActivated: json['account_activated'],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'fname': firstName,
      'lname': lastName,
      'email': email,
      'role': role,
      'profile_photo': profilePhoto,
      'mobile_num': mobileNum,
      'address': address,
      'dob': dob?.toIso8601String().split('T').first,
      'emergency_contact': emergencyContact,
      'course_taken': courseTaken,
      'class_id': classId,
      'department': department,
      'email_verified': emailVerified,
      'account_activated': accountActivated,
    };
  }

  UserModel copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? profilePhoto,
    String? mobileNum,
    String? address,
    DateTime? dob,
    String? emergencyContact,
    String? courseTaken,
    String? classId,
    String? department,
    bool? emailVerified,
    bool? accountActivated,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      mobileNum: mobileNum ?? this.mobileNum,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      courseTaken: courseTaken ?? this.courseTaken,
      classId: classId ?? this.classId,
      department: department ?? this.department,
      emailVerified: emailVerified ?? this.emailVerified,
      accountActivated: accountActivated ?? this.accountActivated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
