class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    String? id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.id = id ?? '',
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  // Add factory constructor fromMap
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: DateTime.parse(map['due_date']),
      priority: map['priority'] ?? 'Normal',
      status: map['status'] ?? 'Pending',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }
}
