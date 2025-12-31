/// Attendance Marking Screen - For Faculty (Full Implementation)
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/attendance_service.dart';
import '../../providers/auth_provider.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  const AttendanceMarkingScreen({super.key});

  @override
  State<AttendanceMarkingScreen> createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  late TabController _tabController;
  
  // Selection state
  String? _selectedClassId;
  String? _selectedSubject;
  String _selectedClassType = 'Theory';
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _attendanceStatus = {};

  // Data state
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  List<String> _subjects = [];
  bool _isLoadingClasses = true;
  bool _isLoadingStudents = false;
  bool _isLoadingSubjects = false;
  bool _isSaving = false;
  
  // History state
  List<SavedAttendance> _savedAttendance = [];
  bool _isLoadingHistory = false;

  final List<String> _classTypes = ['Theory', 'Practical', 'Tutorial', 'Seminar'];

  final List<String> _defaultSubjects = [
    'Data Structures',
    'Database Management',
    'Computer Networks',
    'Operating Systems',
    'Software Engineering',
    'Web Development',
    'Machine Learning',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
    _loadSubjects();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final classes = await _attendanceService.getClasses();
      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      setState(() => _isLoadingClasses = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
      }
    }
  }

  Future<void> _loadSubjects() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final facultyId = authProvider.user?.userId;
    if (facultyId == null) return;

    setState(() => _isLoadingSubjects = true);
    try {
      final subjects = await _attendanceService.getFacultySubjects(facultyId);
      setState(() {
        _subjects = subjects.isNotEmpty ? subjects : _defaultSubjects;
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        _subjects = _defaultSubjects;
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _loadStudents(String classId) async {
    setState(() {
      _isLoadingStudents = true;
      _students = [];
      _attendanceStatus.clear();
    });
    try {
      final students = await _attendanceService.getStudentsByClass(classId);
      setState(() {
        _students = students;
        _isLoadingStudents = false;
        // Initialize all students as present
        for (var student in students) {
          _attendanceStatus[student['user_id'] ?? student['roll_no'] ?? ''] = 'present';
        }
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final facultyId = authProvider.user?.userId;
    if (facultyId == null) return;

    setState(() => _isLoadingHistory = true);
    try {
      final history = await _attendanceService.getFacultyAttendanceHistory(facultyId, limit: 100);
      
      // Group by date, subject, class_id
      final Map<String, SavedAttendance> grouped = {};
      for (var record in history) {
        final key = '${record.date.toIso8601String().split('T').first}_${record.subject}_${record.classId}';
        if (!grouped.containsKey(key)) {
          grouped[key] = SavedAttendance(
            className: record.classId ?? 'Unknown',
            subject: record.subject,
            date: record.date,
            presentCount: 0,
            absentCount: 0,
            lateCount: 0,
            totalStudents: 0,
          );
        }
        grouped[key] = grouped[key]!.copyWith(
          totalStudents: grouped[key]!.totalStudents + 1,
          presentCount: grouped[key]!.presentCount + (record.isPresent ? 1 : 0),
          absentCount: grouped[key]!.absentCount + (record.isAbsent ? 1 : 0),
          lateCount: grouped[key]!.lateCount + (record.isLate ? 1 : 0),
        );
      }
      
      setState(() {
        _savedAttendance = grouped.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var student in _students) {
        final studentId = student['user_id'] ?? student['roll_no'] ?? '';
        _attendanceStatus[studentId] = status;
      }
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null || _selectedSubject == null || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select class and subject first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      
      // Prepare student attendance data
      final studentRecords = _students.map((student) {
        final studentId = student['user_id'] ?? student['roll_no'] ?? '';
        return {
          'user_id': studentId,
          'student_id': studentId,
          'student_name': '${student['fname'] ?? ''} ${student['lname'] ?? ''}'.trim(),
          'roll_no': student['roll_no'] ?? '',
          'department': student['department'],
          'status': _attendanceStatus[studentId] ?? 'present',
        };
      }).toList();

      // Save to database
      final success = await _attendanceService.markAttendance(
        classId: _selectedClassId!,
        subject: _selectedSubject!,
        classType: _selectedClassType,
        markedBy: user?.userId ?? '',
        facultyName: '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
        students: studentRecords,
      );

      if (success) {
        // Add to local history
        final className = _classes.firstWhere(
          (c) => c['class_id'] == _selectedClassId,
          orElse: () => {'class_name': _selectedClassId},
        )['class_name'] ?? _selectedClassId!;
        
        setState(() {
          _savedAttendance.insert(0, SavedAttendance(
            className: className,
            subject: _selectedSubject!,
            date: _selectedDate,
            presentCount: _attendanceStatus.values.where((s) => s == 'present').length,
            absentCount: _attendanceStatus.values.where((s) => s == 'absent').length,
            lateCount: _attendanceStatus.values.where((s) => s == 'late').length,
            totalStudents: _students.length,
          ));
          // Reset form
          _selectedClassId = null;
          _selectedSubject = null;
          _students = [];
          _attendanceStatus.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Attendance saved successfully!'),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Mark', icon: Icon(Iconsax.edit, size: 20)),
            Tab(text: 'History', icon: Icon(Iconsax.clock, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarkTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildMarkTab() {
    return Column(
      children: [
        // Selection Area
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Date Selector
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.calendar, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Class Dropdown
              _isLoadingClasses
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        prefixIcon: Icon(Iconsax.people),
                        border: OutlineInputBorder(),
                      ),
                      items: _classes.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem<String>(
                          value: c['class_id'] as String,
                          child: Text((c['class_name'] as String?) ?? (c['class_id'] as String)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClassId = value);
                        if (value != null) _loadStudents(value);
                      },
                    ),
              const SizedBox(height: 12),
              // Subject Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Select Subject',
                  prefixIcon: Icon(Iconsax.book),
                  border: OutlineInputBorder(),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSubject = value),
              ),
              const SizedBox(height: 12),
              // Class Type
              DropdownButtonFormField<String>(
                value: _selectedClassType,
                decoration: const InputDecoration(
                  labelText: 'Class Type',
                  prefixIcon: Icon(Iconsax.category),
                  border: OutlineInputBorder(),
                ),
                items: _classTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedClassType = value);
                },
              ),
            ],
          ),
        ),

        if (_selectedClassId != null && _selectedSubject != null && !_isLoadingStudents) ...[
          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAll('present'),
                    icon: const Icon(Iconsax.tick_circle, size: 18),
                    label: const Text('All Present'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.success,
                      side: const BorderSide(color: AppTheme.success),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAll('absent'),
                    icon: const Icon(Iconsax.close_circle, size: 18),
                    label: const Text('All Absent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistics Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Present', _attendanceStatus.values.where((s) => s == 'present').length, AppTheme.success),
                _buildStatItem('Absent', _attendanceStatus.values.where((s) => s == 'absent').length, AppTheme.error),
                _buildStatItem('Late', _attendanceStatus.values.where((s) => s == 'late').length, AppTheme.warning),
                _buildStatItem('Total', _students.length, AppTheme.primaryBlue),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final studentId = student['user_id'] ?? student['roll_no'] ?? '';
                final status = _attendanceStatus[studentId] ?? 'present';
                return _buildStudentCard(student, status, index);
              },
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ] else if (_isLoadingStudents)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.clipboard_text,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select class and subject\nto mark attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No attendance records yet',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedAttendance.length,
        itemBuilder: (context, index) {
          final attendance = _savedAttendance[index];
          return _buildHistoryCard(attendance, index);
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, String status, int index) {
    final studentId = student['user_id'] ?? student['roll_no'] ?? '';
    final studentName = '${student['fname'] ?? ''} ${student['lname'] ?? ''}'.trim();
    final rollNo = student['roll_no'] ?? studentId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            child: Text(
              studentName.isNotEmpty ? studentName.substring(0, 1).toUpperCase() : 'S',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName.isNotEmpty ? studentName : 'Student',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  rollNo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildStatusChip('P', 'present', status, studentId),
              const SizedBox(width: 8),
              _buildStatusChip('A', 'absent', status, studentId),
              const SizedBox(width: 8),
              _buildStatusChip('L', 'late', status, studentId),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }

  Widget _buildStatusChip(
    String label,
    String value,
    String currentStatus,
    String studentId,
  ) {
    final isSelected = currentStatus == value;
    final color = value == 'present'
        ? AppTheme.success
        : value == 'absent'
            ? AppTheme.error
            : AppTheme.warning;

    return GestureDetector(
      onTap: () => setState(() => _attendanceStatus[studentId] = value),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(SavedAttendance attendance, int index) {
    final dateStr = '${attendance.date.day}/${attendance.date.month}/${attendance.date.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attendance.className,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHistoryStatChip('P', attendance.presentCount, AppTheme.success),
              const SizedBox(width: 8),
              _buildHistoryStatChip('A', attendance.absentCount, AppTheme.error),
              const SizedBox(width: 8),
              _buildHistoryStatChip('L', attendance.lateCount, AppTheme.warning),
              const Spacer(),
              Text(
                '${attendance.totalStudents} students',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildHistoryStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SavedAttendance {
  final String className;
  final String subject;
  final DateTime date;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int totalStudents;

  SavedAttendance({
    required this.className,
    required this.subject,
    required this.date,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.totalStudents,
  });

  SavedAttendance copyWith({
    String? className,
    String? subject,
    DateTime? date,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? totalStudents,
  }) {
    return SavedAttendance(
      className: className ?? this.className,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      totalStudents: totalStudents ?? this.totalStudents,
    );
  }
}
