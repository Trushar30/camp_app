/// App Router Configuration
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

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen());
      case login:
        return _slideRoute(const LoginScreen());
      case home:
        return _fadeRoute(const MainShell());
      case schedule:
        return _slideRoute(const ScheduleScreen());
      case events:
        return _slideRoute(const EventsScreen());
      case profile:
        return _slideRoute(const ProfileScreen());
      case attendance:
        return _slideRoute(const AttendanceViewScreen());
      case reportProblem:
        return _slideRoute(const ProblemReportScreen());
      case myReports:
        return _slideRoute(const MyReportsScreen());
      case markAttendance:
        return _slideRoute(const AttendanceMarkingScreen());
      case announcements:
        return _slideRoute(const AnnouncementsScreen());
      case resources:
        return _slideRoute(const ResourcesScreen());
      default:
        return _fadeRoute(const SplashScreen());
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
