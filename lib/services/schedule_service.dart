/// Schedule Service
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_model.dart';
import '../config/supabase_config.dart';

class ScheduleService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Fetch schedule for a specific class and day
  Future<List<ScheduleModel>> getSchedule({
    required String classId,
    required int dayIndex,
  }) async {
    try {
      final response = await _supabase
          .from('class_timetables')
          .select()
          .eq('class_id', classId)
          .eq('day_index', dayIndex)
          .order('slot_index', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ScheduleModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching schedule: $e');
      return [];
    }
  }
}
