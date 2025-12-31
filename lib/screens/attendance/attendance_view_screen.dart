/// Attendance View Screen - For Students (Full Implementation)
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';

class AttendanceViewScreen extends StatefulWidget {
  const AttendanceViewScreen({super.key});

  @override
  State<AttendanceViewScreen> createState() => _AttendanceViewScreenState();
}

class _AttendanceViewScreenState extends State<AttendanceViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<SubjectAttendance> _subjects = [];
  List<AttendanceModel> _recentRecords = [];
  Map<String, dynamic> _stats = {};
  final AttendanceService _attendanceService = AttendanceService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAttendanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceData() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.userId;

    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch all records
      final records = await _attendanceService.getStudentAttendance(userId);
      
      // Get stats
      final stats = await _attendanceService.getStudentStats(userId);

      // Group by subject
      final Map<String, List<AttendanceModel>> grouped = {};
      for (var record in records) {
        if (!grouped.containsKey(record.subject)) {
          grouped[record.subject] = [];
        }
        grouped[record.subject]!.add(record);
      }

      // Create SubjectAttendance list
      final List<SubjectAttendance> calculatedSubjects = [];
      int colorIndex = 0;
      final colors = [
        AppTheme.primaryBlue,
        AppTheme.secondaryTeal,
        const Color(0xFF8B5CF6),
        const Color(0xFFF59E0B),
        const Color(0xFFEC4899),
        const Color(0xFF10B981),
      ];

      grouped.forEach((subjectName, list) {
        final total = list.length;
        final attended = list.where((r) => r.isPresent).length;
        final late = list.where((r) => r.isLate).length;
        
        calculatedSubjects.add(SubjectAttendance(
          name: subjectName,
          attended: attended,
          late: late,
          total: total,
          color: colors[colorIndex % colors.length],
          records: list,
        ));
        colorIndex++;
      });

      // Sort by percentage (lowest first to highlight problematic subjects)
      calculatedSubjects.sort((a, b) {
        final aPercent = a.total > 0 ? (a.attended + a.late) / a.total : 0;
        final bPercent = b.total > 0 ? (b.attended + b.late) / b.total : 0;
        return aPercent.compareTo(bPercent);
      });

      if (mounted) {
        setState(() {
          _subjects = calculatedSubjects;
          _recentRecords = records.take(10).toList();
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _overallAttendance {
    if (_subjects.isEmpty) return 0;
    final totalAttended = _subjects.fold(0, (sum, s) => sum + s.attended + s.late);
    final total = _subjects.fold(0, (sum, s) => sum + s.total);
    return total > 0 ? totalAttended / total : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _fetchAttendanceData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendanceData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_subjects.isEmpty)
              _buildEmptyState()
            else ...[
              // Overall Attendance Card
              _buildOverallCard(),
              
              const SizedBox(height: 20),
              
              // Quick Stats Row
              Row(
                children: [
                  Expanded(child: _buildQuickStatCard('Present', _stats['present'] ?? 0, AppTheme.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickStatCard('Absent', _stats['absent'] ?? 0, AppTheme.error)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickStatCard('Late', _stats['late'] ?? 0, AppTheme.warning)),
                ],
              ),
              
              const SizedBox(height: 28),

              // Subject-wise breakdown
              const Text(
                'Subject-wise Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              ...List.generate(_subjects.length, (index) {
                final subject = _subjects[index];
                return _buildSubjectCard(subject, index);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_recentRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No attendance records',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<AttendanceModel>> groupedByDate = {};
    for (var record in _recentRecords) {
      final dateKey = '${record.date.day}/${record.date.month}/${record.date.year}';
      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(record);
    }

    return RefreshIndicator(
      onRefresh: _fetchAttendanceData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedByDate.length,
        itemBuilder: (context, index) {
          final date = groupedByDate.keys.elementAt(index);
          final records = groupedByDate[date]!;
          return _buildDateSection(date, records, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Iconsax.calendar_tick, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Your attendance will appear here once recorded',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 10,
            percent: _overallAttendance.clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_overallAttendance * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Overall',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1000,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _overallAttendance >= 0.75
                      ? '✅ Great job! Keep it up'
                      : _overallAttendance >= 0.60
                          ? '⚠️ Needs improvement'
                          : '🚨 Critical! Attend more classes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Min Required: 75%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildQuickStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(SubjectAttendance subject, int index) {
    final percentage = subject.total > 0 
        ? (subject.attended + subject.late) / subject.total 
        : 0.0;
    
    final status = percentage >= 0.75
        ? 'Good'
        : percentage >= 0.60
            ? 'Warning'
            : 'Critical';
    final statusColor = percentage >= 0.75
        ? AppTheme.success
        : percentage >= 0.60
            ? AppTheme.warning
            : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: subject.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Iconsax.book,
                  color: subject.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${subject.attended} present, ${subject.late} late / ${subject.total} classes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(subject.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subject.color,
                ),
              ),
              Text(
                'Target: 75%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildDateSection(String date, List<AttendanceModel> records, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ...records.map((record) => _buildRecordCard(record)),
        const SizedBox(height: 8),
      ],
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn();
  }

  Widget _buildRecordCard(AttendanceModel record) {
    final statusColor = record.isPresent
        ? AppTheme.success
        : record.isLate
            ? AppTheme.warning
            : AppTheme.error;
    final statusText = record.isPresent
        ? 'Present'
        : record.isLate
            ? 'Late'
            : 'Absent';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${record.classType} • ${record.facultyName ?? 'Faculty'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectAttendance {
  final String name;
  final int attended;
  final int late;
  final int total;
  final Color color;
  final List<AttendanceModel> records;

  SubjectAttendance({
    required this.name,
    required this.attended,
    this.late = 0,
    required this.total,
    required this.color,
    this.records = const [],
  });
}
