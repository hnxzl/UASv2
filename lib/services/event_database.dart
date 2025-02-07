import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import 'notification_service.dart';

class EventDatabase {
  final SupabaseClient supabase;

  EventDatabase({required this.supabase});

  Stream<List<EventModel>> getEventsByUser(String userId) {
    return supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('event_date')
        .map((events) =>
            events.map((event) => EventModel.fromMap(event)).toList());
  }

  Future<void> createEvent(EventModel event) async {
    try {
      await supabase.from('events').insert(event.toMap());

      // 🔔 Jadwalkan notifikasi
      await NotificationService.scheduleNotification(
        event.id.hashCode, // ID unik
        "Upcoming Event: ${event.title}",
        "Event on ${event.eventDate}",
        event.eventDate,
      );
    } catch (e) {
      print('Error in createEvent: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> updateEvent(EventModel event) async {
    await supabase.from('events').update(event.toMap()).eq('id', event.id);
  }

  Future<void> deleteEvent(String eventId) async {
    await supabase.from('events').delete().eq('id', eventId);
  }

  Future<List<EventModel>> getUpcomingEvents(String userId) async {
    final events = await supabase
        .from('events')
        .select()
        .eq('user_id', userId)
        .gte('event_date', DateTime.now().toIso8601String())
        .order('event_date');

    return events.map((event) => EventModel.fromMap(event)).toList();
  }
}
