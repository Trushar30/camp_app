/// ML Service - Priority Prediction Service
/// Matches web version ML service for priority prediction
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class MLService {
  // Use production URL or localhost for development
  static const String baseUrl = 'https://campus-ease-priority-api.onrender.com';
  // For local development, use: 'http://localhost:5000';

  /// Check if ML service is available
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.connectionTimeout);
      return response.statusCode == 200;
    } catch (e) {
      print('ML service health check failed: $e');
      return false;
    }
  }

  /// Predict priority for a report
  Future<MLPrediction> predictPriority(Map<String, dynamic> reportData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(reportData),
          )
          .timeout(AppConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MLPrediction(
          priorityLevel: data['priority_level'] ?? 1,
          priorityText: data['priority_text'] ?? 'Medium',
          confidence: data['confidence']?.toDouble() ?? 0.5,
        );
      } else {
        throw Exception('Prediction service returned error: ${response.statusCode}');
      }
    } catch (e) {
      print('Priority prediction failed: $e');
      // Return default medium priority on error
      return MLPrediction(
        priorityLevel: 1,
        priorityText: 'Medium',
        confidence: 0.0,
      );
    }
  }
}

/// ML Prediction Result
class MLPrediction {
  final int priorityLevel;
  final String priorityText;
  final double confidence;

  MLPrediction({
    required this.priorityLevel,
    required this.priorityText,
    required this.confidence,
  });
}
