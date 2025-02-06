class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled',
      content: map['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
    };
  }
}
