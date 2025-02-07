import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import 'notification_service.dart';

class TaskDatabase {
  final SupabaseClient supabase;

  TaskDatabase({required this.supabase});

  /// Fetch tasks by user ID
  Stream<List<TaskModel>> getTasksByUser(String userId) {
    return supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('due_date', ascending: true)
        .map((data) => data.map((task) => TaskModel.fromMap(task)).toList());
  }

  /// Create new task
  Future<void> createTask(TaskModel task) async {
    try {
      final response = await supabase
          .from('tasks')
          .insert(task.toMap())
          .select('id')
          .single();

      print('Task created with ID: ${response['id']}');

      // 🔔 Jadwalkan notifikasi
      await NotificationService.scheduleNotification(
        response['id'].hashCode, // ID unik
        "Reminder: ${task.title}",
        "Due at ${task.dueDate}",
        task.dueDate,
      );
    } catch (e) {
      print('Error in createTask: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update task
  Future<void> updateTask(TaskModel task) async {
    await supabase.from('tasks').update(task.toMap()).eq('id', task.id);
  }

  /// Delete task
  Future<bool> deleteTask(TaskModel task) async {
    final response = await supabase.from('tasks').delete().eq('id', task.id);
    return response != null;
  }
}
