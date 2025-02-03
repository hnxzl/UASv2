import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient supabase;

  TaskService({required this.supabase});

  Future<List<Map<String, dynamic>>> getTodayTasks(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await supabase
        .from('tasks')
        .select('*')
        .eq('user_id', userId)
        .gte('due_date', today)
        .lte('due_date', today);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllTasks(String userId) async {
    final response = await supabase
        .from('tasks')
        .select('*')
        .eq('user_id', userId)
        .order('due_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final response = await supabase.from('tasks').select();
    return response;
  }

  Future<void> addTask(String userId, String title, String description,
      String dueDate, int priority, String status) async {
    await supabase.from('tasks').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'priority': priority,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String()
    });
  }

  Future<void> updateTask(String taskId, String title, String description,
      String dueDate, int priority, String status) async {
    await supabase.from('tasks').update({
      'title': title,
      'description': description,
      'due_date': dueDate,
      'priority': priority,
      'status': status,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await supabase.from('tasks').delete().eq('id', taskId);
  }
}
