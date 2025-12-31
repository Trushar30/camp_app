/// Reports Service - Problem reporting Supabase operations
library;

import '../config/supabase_config.dart';

class ReportsService {
  final _client = SupabaseConfig.client;

  /// Submit a problem report
  Future<bool> submitReport({
    required String category,
    required String location,
    required String impactScope,
    required String description,
    required String reporterId,
    String? images,
  }) async {
    try {
      await _client.from('report').insert({
        'Problem_Category': category,
        'Location': location,
        'Impact_Scope': impactScope,
        'description': {'text': description},
        'reporter_id': reporterId,
        'images': images,
        'Reporter_Type': 'student',
        'priority_level': 2,
        'priority_text': 'Medium',
        'resolved': false,
      });
      return true;
    } catch (e) {
      print('Error submitting report: $e');
      return false;
    }
  }

  /// Get reports submitted by a user
  Future<List<Map<String, dynamic>>> getUserReports(String reporterId) async {
    try {
      final response = await _client
          .from('report')
          .select()
          .eq('reporter_id', reporterId)
          .order('id', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  /// Get all reports (admin only)
  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final response = await _client
          .from('report')
          .select()
          .order('priority_level', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all reports: $e');
      return [];
    }
  }

  /// Update report status
  Future<bool> updateReportStatus(int reportId, bool resolved) async {
    try {
      await _client.from('report').update({
        'resolved': resolved,
        'resolved_at': resolved ? DateTime.now().toIso8601String() : null,
      }).eq('id', reportId);
      return true;
    } catch (e) {
      print('Error updating report: $e');
      return false;
    }
  }
}
