class EventModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    String? id,
    required this.userId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.id = id ?? '',
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: DateTime.parse(map['event_date']),
      location: map['location'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }
}
