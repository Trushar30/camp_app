/// Main Shell - Bottom Navigation Container
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'home_screen.dart';
import '../schedule/schedule_screen.dart';
import '../attendance/attendance_view_screen.dart';
import '../faculty/attendance_marking_screen.dart';
import '../services/services_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _studentPages = [
    const HomeScreen(),
    const ScheduleScreen(),
    const AttendanceViewScreen(),
    const ServicesScreen(),
  ];

  final List<Widget> _facultyPages = [
    const HomeScreen(),
    const ScheduleScreen(),
    const AttendanceMarkingScreen(),
    const ServicesScreen(),
  ];

  List<BottomNavItem> get _studentNavItems => [
    BottomNavItem(icon: Iconsax.home, activeIcon: Iconsax.home_15, label: 'Home'),
    BottomNavItem(icon: Iconsax.calendar, activeIcon: Iconsax.calendar5, label: 'Schedule'),
    BottomNavItem(icon: Iconsax.chart, activeIcon: Iconsax.chart_15, label: 'Attendance'),
    BottomNavItem(icon: Iconsax.element_4, activeIcon: Iconsax.element_45, label: 'Service'),
  ];

  List<BottomNavItem> get _facultyNavItems => [
    BottomNavItem(icon: Iconsax.home, activeIcon: Iconsax.home_15, label: 'Home'),
    BottomNavItem(icon: Iconsax.calendar, activeIcon: Iconsax.calendar5, label: 'Schedule'),
    BottomNavItem(icon: Iconsax.chart, activeIcon: Iconsax.chart_15, label: 'Attendance'),
    BottomNavItem(icon: Iconsax.element_4, activeIcon: Iconsax.element_45, label: 'Service'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFaculty = authProvider.isFaculty;
    final pages = isFaculty ? _facultyPages : _studentPages;
    final navItems = isFaculty ? _facultyNavItems : _studentNavItems;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = _currentIndex == index;

                return GestureDetector(
                  onTap: () => _onNavTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 24,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textSecondaryLight,
                        )
                            .animate(target: isSelected ? 1 : 0)
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 150.ms,
                            ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
