/// Attendance Service - Full Implementation matching Web
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';
import '../config/supabase_config.dart';

class AttendanceService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Fetch all attendance records for a specific student
  Future<List<AttendanceModel>> getStudentAttendance(String userId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  /// Fetch attendance for a specific date and subject
  Future<List<AttendanceModel>> getAttendanceByDateAndSubject({
    required String classId,
    required String date,
    required String subject,
    required String markedBy,
  }) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('class_id', classId)
          .eq('date', date)
          .eq('subject', subject)
          .eq('marked_by', markedBy);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching attendance by date/subject: $e');
      return [];
    }
  }

  /// Get attendance history for faculty
  Future<List<AttendanceModel>> getFacultyAttendanceHistory(String facultyId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('marked_by', facultyId)
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching faculty attendance history: $e');
      return [];
    }
  }

  /// Get attendance summary grouped by date for faculty
  Future<List<Map<String, dynamic>>> getAttendanceSummary(String facultyId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select('date, subject, class_id, status')
          .eq('marked_by', facultyId)
          .order('date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      // Group by date and subject
      final Map<String, Map<String, dynamic>> grouped = {};
      for (var record in data) {
        final key = '${record['date']}_${record['subject']}_${record['class_id']}';
        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'date': record['date'],
            'subject': record['subject'],
            'class_id': record['class_id'],
            'present': 0,
            'absent': 0,
            'late': 0,
            'total': 0,
          };
        }
        grouped[key]!['total'] = (grouped[key]!['total'] as int) + 1;
        final status = record['status'] as String;
        grouped[key]![status] = (grouped[key]![status] ?? 0) + 1;
      }
      
      return grouped.values.toList();
    } catch (e) {
      print('Error fetching attendance summary: $e');
      return [];
    }
  }

  // --- Class Management Methods ---

  /// Fetch all classes
  Future<List<Map<String, dynamic>>> getClasses() async {
    try {
      final response = await _supabase
          .from('class_details')
          .select('class_id, class_name, department, institute, semester, academic_year')
          .order('class_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching classes: $e');
      return [];
    }
  }

  /// Fetch students by class_id
  Future<List<Map<String, dynamic>>> getStudentsByClass(String classId) async {
    try {
      final response = await _supabase
          .from('student_records')
          .select('user_id, fname, lname, roll_no, department, email')
          .eq('class_id', classId)
          .order('roll_no');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  /// Fetch subjects from faculty timetable
  Future<List<String>> getFacultySubjects(String facultyId) async {
    try {
      final response = await _supabase
          .from('faculty_timetables')
          .select('course')
          .eq('faculty_id', facultyId);

      final List<dynamic> data = response as List<dynamic>;
      final subjects = data
          .map((item) => item['course'] as String?)
          .where((course) => course != null && course.isNotEmpty)
          .toSet()
          .toList();
      
      return subjects.cast<String>();
    } catch (e) {
      print('Error fetching faculty subjects: $e');
      // Return default subjects
      return [
        'Data Structures',
        'Database Management',
        'Computer Networks',
        'Operating Systems',
        'Software Engineering',
        'Web Development',
        'Machine Learning',
      ];
    }
  }

  /// Mark attendance for a list of students
  Future<bool> markAttendance({
    required String classId,
    required String subject,
    required String classType,
    required String markedBy,
    required String facultyName,
    required List<Map<String, dynamic>> students,
  }) async {
    try {
      final date = DateTime.now().toIso8601String().split('T').first;
      
      final List<Map<String, dynamic>> records = students.map((s) {
        return {
          'user_id': s['user_id'] ?? s['student_id'],
          'student_id': s['student_id'] ?? s['user_id'],
          'student_name': s['student_name'] ?? '${s['fname'] ?? ''} ${s['lname'] ?? ''}'.trim(),
          'roll_no': s['roll_no'],
          'class_id': classId,
          'department': s['department'],
          'date': date,
          'subject': subject,
          'class_type': classType,
          'status': s['status'] ?? 'present',
          'marked_by': markedBy,
          'faculty_name': facultyName,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      // Use upsert to handle duplicates (update if exists)
      await _supabase.from('attendance').upsert(
        records,
        onConflict: 'user_id,date,subject,class_id,marked_by',
      );
      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  /// Mark single student attendance
  Future<bool> markSingleAttendance({
    required String userId,
    required String studentId,
    required String studentName,
    required String? rollNo,
    required String classId,
    required String? department,
    required String subject,
    required String classType,
    required String status,
    required String markedBy,
    required String facultyName,
  }) async {
    try {
      final date = DateTime.now().toIso8601String().split('T').first;
      
      await _supabase.from('attendance').upsert({
        'user_id': userId,
        'student_id': studentId,
        'student_name': studentName,
        'roll_no': rollNo,
        'class_id': classId,
        'department': department,
        'date': date,
        'subject': subject,
        'class_type': classType,
        'status': status,
        'marked_by': markedBy,
        'faculty_name': facultyName,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date,subject,class_id,marked_by');
      
      return true;
    } catch (e) {
      print('Error marking single attendance: $e');
      return false;
    }
  }

  /// Get student attendance statistics
  Future<Map<String, dynamic>> getStudentStats(String userId) async {
    try {
      final records = await getStudentAttendance(userId);
      
      if (records.isEmpty) {
        return {
          'total': 0,
          'present': 0,
          'absent': 0,
          'late': 0,
          'percentage': 0.0,
        };
      }

      final total = records.length;
      final present = records.where((r) => r.isPresent).length;
      final absent = records.where((r) => r.isAbsent).length;
      final late = records.where((r) => r.isLate).length;
      final percentage = (present / total) * 100;

      return {
        'total': total,
        'present': present,
        'absent': absent,
        'late': late,
        'percentage': percentage,
      };
    } catch (e) {
      print('Error fetching student stats: $e');
      return {
        'total': 0,
        'present': 0,
        'absent': 0,
        'late': 0,
        'percentage': 0.0,
      };
    }
  }

  /// Get attendance by subject for a student
  Future<Map<String, Map<String, int>>> getAttendanceBySubject(String userId) async {
    try {
      final records = await getStudentAttendance(userId);
      
      final Map<String, Map<String, int>> subjectStats = {};
      
      for (var record in records) {
        final subject = record.subject;
        if (!subjectStats.containsKey(subject)) {
          subjectStats[subject] = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
        }
        subjectStats[subject]!['total'] = (subjectStats[subject]!['total'] ?? 0) + 1;
        if (record.isPresent) {
          subjectStats[subject]!['present'] = (subjectStats[subject]!['present'] ?? 0) + 1;
        } else if (record.isAbsent) {
          subjectStats[subject]!['absent'] = (subjectStats[subject]!['absent'] ?? 0) + 1;
        } else if (record.isLate) {
          subjectStats[subject]!['late'] = (subjectStats[subject]!['late'] ?? 0) + 1;
        }
      }
      
      return subjectStats;
    } catch (e) {
      print('Error fetching attendance by subject: $e');
      return {};
    }
  }
}
