/// Attendance Model
library;

class AttendanceModel {
  final String id;
  final String userId;
  final String studentId;
  final String studentName;
  final String? rollNo;
  final String? classId;
  final String? department;
  final String subject;
  final String status;
  final DateTime date;
  final String classType;
  final String markedBy;
  final String? facultyName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.studentId,
    required this.studentName,
    this.rollNo,
    this.classId,
    this.department,
    required this.subject,
    required this.status,
    required this.date,
    required this.classType,
    required this.markedBy,
    this.facultyName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPresent => status.toLowerCase() == 'present';
  bool get isAbsent => status.toLowerCase() == 'absent';
  bool get isLate => status.toLowerCase() == 'late';

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? '',
      studentId: json['student_id'] ?? json['user_id'] ?? '',
      studentName: json['student_name'] ?? '',
      rollNo: json['roll_no'],
      classId: json['class_id'],
      department: json['department'],
      subject: json['subject'] ?? '',
      status: json['status'] ?? 'absent',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      classType: json['class_type'] ?? '',
      markedBy: json['marked_by'] ?? '',
      facultyName: json['faculty_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'student_id': studentId,
      'student_name': studentName,
      'roll_no': rollNo,
      'class_id': classId,
      'department': department,
      'subject': subject,
      'status': status,
      'date': date.toIso8601String().split('T').first,
      'class_type': classType,
      'marked_by': markedBy,
      'faculty_name': facultyName,
    };
  }
}
