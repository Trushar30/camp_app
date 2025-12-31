/// Home Screen with dashboard features
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/announcements_service.dart';
import '../../widgets/cards/feature_card.dart';
import '../../widgets/cards/quick_stat_card.dart';
import '../../widgets/cards/announcement_card.dart';
import '../../widgets/common/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final AnnouncementsService _announcementsService = AnnouncementsService();
  
  String _attendancePercent = '--';
  int _pendingCount = 0;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Fetch attendance data
      final attendanceRecords = await _attendanceService.getStudentAttendance(user.userId);
      
      if (attendanceRecords.isNotEmpty) {
        final presentCount = attendanceRecords.where((a) => a.status == 'present').length;
        final totalCount = attendanceRecords.length;
        final percent = (presentCount / totalCount * 100).round();
        _attendancePercent = '$percent%';
      } else {
        _attendancePercent = 'N/A';
      }

      // Fetch announcements
      final announcements = await _announcementsService.getAnnouncements(limit: 3);
      _announcements = announcements;

      // Calculate pending (high priority announcements as "pending" items)
      _pendingCount = announcements.where((a) => a['priority'] == 'high').length;

    } catch (e) {
      print('Error loading dashboard data: $e');
      _attendancePercent = '--';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            // Hero Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ).animate().fadeIn(delay: 100.ms),
                                const SizedBox(height: 4),
                                Text(
                                  user?.firstName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ).animate().fadeIn(delay: 200.ms).slideX(
                                      begin: -0.1,
                                      end: 0,
                                    ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Iconsax.notification,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pushNamed(context, '/announcements'),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/profile'),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    child: Text(
                                      user?.firstName.substring(0, 1).toUpperCase() ??
                                          'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ).animate().scale(delay: 300.ms),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Welcome Banner
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome to CampusEase',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your complete campus management companion',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Iconsax.book_1,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(delay: 400.ms)
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Quick Stats'),
                    const SizedBox(height: 16),
                    AnimationLimiter(
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimationConfiguration.staggeredList(
                              position: 0,
                              duration: const Duration(milliseconds: 400),
                              child: SlideAnimation(
                                horizontalOffset: -50,
                                child: FadeInAnimation(
                                  child: QuickStatCard(
                                    icon: Iconsax.calendar_tick,
                                    title: 'Attendance',
                                    value: _isLoading ? '...' : _attendancePercent,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimationConfiguration.staggeredList(
                              position: 1,
                              duration: const Duration(milliseconds: 400),
                              child: SlideAnimation(
                                horizontalOffset: 50,
                                child: FadeInAnimation(
                                  child: QuickStatCard(
                                    icon: Iconsax.task_square,
                                    title: 'Important',
                                    value: _isLoading ? '...' : '$_pendingCount',
                                    color: AppTheme.warning,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Feature Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Quick Access'),
                    const SizedBox(height: 16),
                    AnimationLimiter(
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          AnimationConfiguration.staggeredGrid(
                            position: 0,
                            columnCount: 2,
                            duration: const Duration(milliseconds: 400),
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: FeatureCard(
                                  icon: Iconsax.calendar,
                                  title: 'Schedule',
                                  subtitle: 'View classes',
                                  gradient: AppTheme.primaryGradient,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/schedule',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimationConfiguration.staggeredGrid(
                            position: 1,
                            columnCount: 2,
                            duration: const Duration(milliseconds: 400),
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: FeatureCard(
                                  icon: Iconsax.chart,
                                  title: 'Attendance',
                                  subtitle: authProvider.isFaculty ? 'Mark attendance' : 'Track records',
                                  gradient: AppTheme.tealGradient,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    authProvider.isFaculty ? '/mark-attendance' : '/attendance',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimationConfiguration.staggeredGrid(
                            position: 2,
                            columnCount: 2,
                            duration: const Duration(milliseconds: 400),
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: FeatureCard(
                                  icon: Iconsax.calendar_tick,
                                  title: 'Events',
                                  subtitle: 'Upcoming',
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                  ),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/events',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimationConfiguration.staggeredGrid(
                            position: 3,
                            columnCount: 2,
                            duration: const Duration(milliseconds: 400),
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: FeatureCard(
                                  icon: Iconsax.message_question,
                                  title: 'Report',
                                  subtitle: 'Submit issue',
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  ),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/report-problem',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Announcements
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Announcements',
                      actionText: 'See All',
                      onActionTap: () => Navigator.pushNamed(context, '/announcements'),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_announcements.isEmpty)
                      Center(
                        child: Text(
                          'No announcements',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    else
                      ..._announcements.take(2).map((announcement) {
                        final index = _announcements.indexOf(announcement);
                        return Column(
                          children: [
                            AnnouncementCard(
                              title: announcement['title'] ?? '',
                              description: announcement['content'] ?? '',
                              date: _formatDate(announcement['created_at']),
                              isImportant: announcement['priority'] == 'high',
                            ).animate(delay: Duration(milliseconds: 600 + (index * 100))).fadeIn().slideX(begin: 0.1, end: 0),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
