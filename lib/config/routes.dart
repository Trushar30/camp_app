/// App Router Configuration - Enhanced with premium transitions
library;

import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/attendance/attendance_view_screen.dart';
import '../screens/reports/problem_report_screen.dart';
import '../screens/reports/my_reports_screen.dart';
import '../screens/faculty/attendance_marking_screen.dart';
import '../screens/announcements/announcements_screen.dart';
import '../screens/resources/resources_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String events = '/events';
  static const String profile = '/profile';
  static const String attendance = '/attendance';
  static const String reportProblem = '/report-problem';
  static const String myReports = '/my-reports';
  static const String markAttendance = '/mark-attendance';
  static const String announcements = '/announcements';
  static const String resources = '/resources';

  // Premium easing curves for smooth transitions
  static const Curve _smoothCurve = Curves.easeOutCubic;
  static const Curve _bounceCurve = Curves.easeOutBack;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen());
      case login:
        return _scaleFadeRoute(const LoginScreen());
      case home:
        return _fadeRoute(const MainShell());
      case schedule:
        return _sharedAxisRoute(const ScheduleScreen());
      case events:
        return _sharedAxisRoute(const EventsScreen());
      case profile:
        return _slideUpRoute(const ProfileScreen());
      case attendance:
        return _sharedAxisRoute(const AttendanceViewScreen());
      case reportProblem:
        return _slideUpRoute(const ProblemReportScreen());
      case myReports:
        return _sharedAxisRoute(const MyReportsScreen());
      case markAttendance:
        return _sharedAxisRoute(const AttendanceMarkingScreen());
      case announcements:
        return _sharedAxisRoute(const AnnouncementsScreen());
      case resources:
        return _sharedAxisRoute(const ResourcesScreen());
      default:
        return _fadeRoute(const SplashScreen());
    }
  }

  /// Smooth fade transition - ideal for root screens
  static PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: _smoothCurve,
        );
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Scale + Fade combo - perfect for important screens like login
  static PageRouteBuilder _scaleFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: _bounceCurve,
        );
        
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: animation, curve: _smoothCurve),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Shared axis horizontal transition - for list to detail navigation
  static PageRouteBuilder _sharedAxisRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: _smoothCurve,
        );
        
        // Incoming page slides in and fades in
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);
        
        final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
        
        // Outgoing page slides out and fades out
        final secondaryCurved = CurvedAnimation(
          parent: secondaryAnimation,
          curve: _smoothCurve,
        );
        
        final secondarySlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.15, 0),
        ).animate(secondaryCurved);
        
        final secondaryFade = Tween<double>(begin: 1, end: 0.5).animate(secondaryCurved);

        return SlideTransition(
          position: secondarySlide,
          child: FadeTransition(
            opacity: secondaryFade,
            child: SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Slide up transition - for modal-like screens (profile, reports)
  static PageRouteBuilder _slideUpRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: _smoothCurve,
        );
        
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curvedAnimation);
        
        final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
        
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
