import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tododo/models/note_model.dart';

class NoteDatabase {
  final SupabaseClient supabase;

  NoteDatabase({required this.supabase});

  Future<void> createNote(NoteModel note) async {
    await supabase.from('notes').insert({
      'user_id': note.userId,
      'title': note.title.isEmpty ? 'Untitled' : note.title,
      'content': note.content,
    });
  }

  Future<void> updateNote(
      NoteModel note, String newContent, String newTitle) async {
    await supabase.from('notes').update({
      'title': newTitle.isEmpty ? 'Untitled' : newTitle,
      'content': newContent,
    }).match({'id': note.id});
  }

  Stream<List<NoteModel>> getNotesByUser(String userId) {
    return supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          return data
              .map((json) => NoteModel.fromMap({
                    'id': json['id'],
                    'title': json['title'] ?? 'Untitled',
                    'content': json['content'] ?? '',
                    'user_id': json['user_id'],
                  }))
              .toList();
        });
  }

  Future<bool> deleteNote(NoteModel note) async {
    final response =
        await supabase.from('notes').delete().match({'id': note.id});
    return response != null;
  }
}
