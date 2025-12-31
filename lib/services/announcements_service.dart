/// Announcements Service - Fetches announcements from Supabase
library;

import '../config/supabase_config.dart';

class AnnouncementsService {
  final _client = SupabaseConfig.client;

  /// Fetch active announcements
  Future<List<Map<String, dynamic>>> getAnnouncements({int limit = 10}) async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false) // high priority first
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching announcements: $e');
      // Return mock data as fallback
      return _getMockAnnouncements();
    }
  }

  /// Fetch announcements by category
  Future<List<Map<String, dynamic>>> getAnnouncementsByCategory(String category) async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .eq('is_active', true)
          .eq('category', category)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching announcements by category: $e');
      return [];
    }
  }

  // Mock data fallback
  List<Map<String, dynamic>> _getMockAnnouncements() {
    return [
      {
        'id': 1,
        'title': 'Mid-Semester Exams',
        'content': 'Mid-semester examinations will begin from next week. Please check the exam schedule on the notice board.',
        'priority': 'high',
        'category': 'Academic',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 2,
        'title': 'Library Hours Extended',
        'content': 'Library will remain open till 10 PM during exam week for student convenience.',
        'priority': 'normal',
        'category': 'Facility',
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 3,
        'title': 'Campus Placement Drive',
        'content': 'Top MNCs will be visiting campus for recruitment. Register before Dec 30.',
        'priority': 'high',
        'category': 'Career',
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 4,
        'title': 'Winter Break Notice',
        'content': 'Campus will be closed from Jan 1-5 for winter break. Classes resume on Jan 6.',
        'priority': 'normal',
        'category': 'General',
        'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      },
    ];
  }
}
