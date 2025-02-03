import 'package:supabase_flutter/supabase_flutter.dart';

class NoteService {
  final SupabaseClient supabase;

  NoteService({required this.supabase});

  Future<List<Map<String, dynamic>>> getRecentNotes(String userId) async {
    final response = await supabase
        .from('notes')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(5);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllNotes(String userId) async {
    final response = await supabase
        .from('notes')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final response = await supabase.from('notes').select();
    return response;
  }

  Future<void> addNote(String userId, String title, String content) async {
    await supabase.from('notes').insert({
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': DateTime.now().toIso8601String()
    });
  }

  Future<void> updateNote(String noteId, String title, String content) async {
    await supabase.from('notes').update({
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', noteId);
  }

  Future<void> deleteNote(String noteId) async {
    await supabase.from('notes').delete().eq('id', noteId);
  }
}
