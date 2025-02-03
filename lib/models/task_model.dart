import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  // Convert Task to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Convert Map from Supabase to Task object
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      priority: map['priority'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
