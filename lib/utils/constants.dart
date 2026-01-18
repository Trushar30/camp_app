/// App Constants
library;

class AppConstants {
  // App Info
  static const String appName = 'CampusEase';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your complete campus management app';
  
  // ID Patterns (matching web app patterns)
  static final RegExp studentIdPattern = RegExp(r'^[2][0-5](dit|dce|dcs|it|ce|cs)\d{3}$', caseSensitive: false);
  static final RegExp facultyIdPattern = RegExp(r'^fac_(dit|dce|dcs|it|ce|cs)\d{3}$', caseSensitive: false);
  static final RegExp adminIdPattern = RegExp(r'^admin\d{3}$', caseSensitive: false);
  
  // Email Patterns
  static String studentEmail(String id) => '${id.toLowerCase()}@charusat.edu.in';
  static String facultyEmail(String id) => '${id.toLowerCase()}@charusat.ac.in';
  static String adminEmail(String id) => '${id.toLowerCase()}_ad@charusat.ac.in';
  
  // Default Password Generator (for students)
  static String generateDefaultPassword(String studentId) {
    final year = studentId.substring(0, 2);
    return '$studentId@$year';
  }
  
  // User Roles
  static const String roleStudent = 'student';
  static const String roleFaculty = 'faculty';
  static const String roleAdmin = 'admin';
  
  // Attendance Status
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';
  
  // Event Categories
  static const String eventAcademic = 'academic';
  static const String eventCareer = 'career';
  static const String eventSocial = 'social';
  
  // Priority Levels
  static const Map<int, String> priorityLevels = {
    1: 'Low',
    2: 'Medium',
    3: 'High',
    4: 'Critical',
  };
  
  // Storage Keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserId = 'userId';
  static const String keyUserRole = 'userRole';
  static const String keyThemeMode = 'themeMode';
  
  // API Endpoints
  static const String mlApiBaseUrl = 'https://campus-ease-priority-api.onrender.com';
  // For local development: 'http://localhost:5000';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
