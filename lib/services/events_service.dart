/// Events Service - Fetches events data from Supabase
library;

import '../config/supabase_config.dart';

class EventsService {
  final _client = SupabaseConfig.client;

  /// Fetch all events (using 'event' table matching web schema)
  Future<List<Map<String, dynamic>>> getEvents({String? category}) async {
    try {
      var query = _client.from('event').select();
      
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('Etype', category);
      }
      
      final response = await query.order('Date', ascending: true);
      
      // Transform to app-friendly format
      return List<Map<String, dynamic>>.from(response).map((event) {
        return {
          'id': event['id'].toString(),
          'title': event['Ename'] ?? '',
          'description': event['Description'] ?? '',
          'date': event['Date'] ?? '',
          'time': event['Time'] ?? '',
          'location': event['Location'] ?? '',
          'category': event['Etype']?.toString().toLowerCase() ?? 'academic',
          'image': event['Ephoto'],
          'capacity': event['capacity'],
          'registered_count': event['registered_count'],
          'status': event['status'],
          'speaker': event['speaker'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching events: $e');
      // Return mock data for demo
      return _getMockEvents(category);
    }
  }

  /// Register for an event
  Future<bool> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    String? userRole,
    String? department,
    int? semester,
    String? phoneNumber,
  }) async {
    try {
      await _client.from('event_registrations').insert({
        'event_id': int.parse(eventId),
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'user_role': userRole ?? 'student',
        'department': department,
        'semester': semester,
        'phone_number': phoneNumber,
        'registration_date': DateTime.now().toIso8601String(),
      });
      
      // Increment registered count (optional, can be done via trigger)
      await _client.rpc('increment_event_registration', params: {'event_id': int.parse(eventId)}).catchError((_) {});
      
      return true;
    } catch (e) {
      print('Error registering for event: $e');
      return false;
    }
  }

  /// Check if user is registered for an event
  Future<bool> isRegistered(String eventId, String userId) async {
    try {
      final response = await _client
          .from('event_registrations')
          .select('id')
          .eq('event_id', int.parse(eventId))
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Cancel registration
  Future<bool> cancelRegistration(String eventId, String userId) async {
    try {
      await _client
          .from('event_registrations')
          .delete()
          .eq('event_id', int.parse(eventId))
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error cancelling registration: $e');
      return false;
    }
  }

  // Mock events for demo if table doesn't exist
  List<Map<String, dynamic>> _getMockEvents(String? category) {
    final events = [
      {
        'id': '1',
        'title': 'Tech Symposium 2025',
        'description': 'Annual technology symposium featuring industry experts',
        'date': '2025-01-15',
        'time': '10:00 AM',
        'location': 'Main Auditorium',
        'category': 'academic',
      },
      {
        'id': '2',
        'title': 'Campus Placement Drive',
        'description': 'Top MNCs recruiting for software engineering roles',
        'date': '2025-01-20',
        'time': '09:00 AM',
        'location': 'Placement Cell',
        'category': 'career',
      },
      {
        'id': '3',
        'title': 'Cultural Fest',
        'description': 'Annual cultural celebration with music and dance',
        'date': '2025-01-25',
        'time': '05:00 PM',
        'location': 'Open Air Theater',
        'category': 'social',
      },
    ];
    
    if (category == null || category == 'All') {
      return events;
    }
    return events.where((e) => e['category'] == category.toLowerCase()).toList();
  }
}
