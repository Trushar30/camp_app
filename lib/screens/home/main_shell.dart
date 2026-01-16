/// Main Shell - Enhanced Bottom Navigation with Premium Animations
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

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
    BottomNavItem(icon: Iconsax.element_4, activeIcon: Iconsax.element_45, label: 'Services'),
  ];

  List<BottomNavItem> get _facultyNavItems => [
    BottomNavItem(icon: Iconsax.home, activeIcon: Iconsax.home_15, label: 'Home'),
    BottomNavItem(icon: Iconsax.calendar, activeIcon: Iconsax.calendar5, label: 'Schedule'),
    BottomNavItem(icon: Iconsax.chart, activeIcon: Iconsax.chart_15, label: 'Mark'),
    BottomNavItem(icon: Iconsax.element_4, activeIcon: Iconsax.element_45, label: 'Services'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _indicatorAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
    
    _indicatorController.forward(from: 0);
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onNavTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: _AnimatedNavItem(
                      item: item,
                      isSelected: isSelected,
                      animation: isSelected ? _indicatorAnimation : null,
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

class _AnimatedNavItem extends StatefulWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Animation<double>? animation;

  const _AnimatedNavItem({
    required this.item,
    required this.isSelected,
    this.animation,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with bounce and scale
            Transform.translate(
              offset: Offset(0, widget.isSelected ? _bounceAnimation.value : 0),
              child: Transform.scale(
                scale: widget.isSelected ? _scaleAnimation.value : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                        ? AppTheme.primaryBlue.withOpacity(0.12) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                    size: 24,
                    color: widget.isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Label with animated opacity
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: widget.isSelected ? 11 : 10,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondaryLight,
              ),
              child: Text(widget.item.label),
            ),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(top: 4),
              width: widget.isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      },
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

