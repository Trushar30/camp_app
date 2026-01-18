/// Reports Service - Problem reporting Supabase operations
/// Matches web version logic with ML priority prediction
library;

import '../config/supabase_config.dart';
import 'ml_service.dart';

class ReportsService {
  final _client = SupabaseConfig.client;
  final MLService _mlService = MLService();

  /// Fetch dynamic report field configurations
  Future<List<Map<String, dynamic>>> getFieldConfigs() async {
    try {
      final response = await _client
          .from('report_field_config')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching field configs: $e');
      return [];
    }
  }

  /// Submit a problem report with ML priority prediction
  Future<bool> submitReport({
    required String category,
    required String location,
    required String impactScope,
    required String description,
    required String reporterId,
    required String reporterType,
    String? occurrencePattern,
    String? classNo,
    String? images,
    Map<String, dynamic>? additionalFields,
  }) async {
    try {
      // Prepare report data for ML prediction
      final reportDataForML = {
        'Problem_Category': category,
        'Location': location,
        'Impact_Scope': impactScope,
        'Reporter_Type': reporterType,
        'Occurrence_Pattern': occurrencePattern ?? 'First occurrence',
        if (classNo != null) 'class_No': int.tryParse(classNo) ?? classNo,
        ...?additionalFields,
      };

      // Get priority prediction from ML service
      MLPrediction prediction;
      final isMLAvailable = await _mlService.checkHealth();
      
      if (isMLAvailable) {
        prediction = await _mlService.predictPriority(reportDataForML);
      } else {
        // Fallback to default medium priority
        prediction = MLPrediction(
          priorityLevel: 1,
          priorityText: 'Medium',
          confidence: 0.0,
        );
      }

      // Prepare report data for database
      final reportData = {
        'Problem_Category': category,
        'Location': location,
        'Impact_Scope': impactScope,
        'description': {'text': description},
        'reporter_id': reporterId,
        'Reporter_Type': reporterType,
        'priority_level': prediction.priorityLevel,
        'priority_text': prediction.priorityText,
        'resolved': false,
        if (images != null) 'images': images,
        if (occurrencePattern != null) 'Occurrence_Pattern': occurrencePattern,
        if (classNo != null) 'class_No': int.tryParse(classNo) ?? classNo,
        // Add any additional dynamic fields
        ...?additionalFields,
      };

      await _client.from('report').insert(reportData);
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

  /// Get reports with filters (for students/faculty viewing their own reports)
  Future<List<Map<String, dynamic>>> getUserReportsFiltered({
    required String reporterId,
    String? category,
    String? location,
    String? priority,
  }) async {
    try {
      var query = _client
          .from('report')
          .select()
          .eq('reporter_id', reporterId);

      if (category != null && category != 'all') {
        query = query.eq('Problem_Category', category);
      }
      if (location != null && location != 'all') {
        query = query.eq('Location', location);
      }
      if (priority != null && priority != 'all') {
        query = query.eq('priority_text', priority);
      }

      final response = await query.order('id', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching filtered reports: $e');
      return [];
    }
  }


  /// Update report status (students/faculty can't update, but keeping for future use)
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
