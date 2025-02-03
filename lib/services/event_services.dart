import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient supabase;

  EventService({required this.supabase});

  Future<List<Map<String, dynamic>>> getUpcomingEvents(String userId) async {
    final now = DateTime.now().toIso8601String();
    final response = await supabase
        .from('events')
        .select('*')
        .eq('user_id', userId)
        .gte('start_time', now)
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllEvents(String userId) async {
    final response = await supabase
        .from('events')
        .select('*')
        .eq('user_id', userId)
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final response = await supabase.from('events').select();
    return response;
  }

  Future<void> addEvent(String userId, String title, String description,
      String startTime, String endTime, String location) async {
    await supabase.from('events').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'created_at': DateTime.now().toIso8601String()
    });
  }

  Future<void> updateEvent(String eventId, String title, String description,
      String startTime, String endTime, String location) async {
    await supabase.from('events').update({
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    await supabase.from('events').delete().eq('id', eventId);
  }
}
