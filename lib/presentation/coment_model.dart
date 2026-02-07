class Comment {
  final int id;
  final String content;
  final String author;
  final String avatarUrl;
  final String timeCreated; // Moodle lo manda ya formateado a veces, o timestamp

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.avatarUrl,
    required this.timeCreated,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json['id'].toString()),
      content: json['content'] ?? '',
      author: json['fullname'] ?? 'Anónimo',
      avatarUrl: json['avatar'] ?? '',
      timeCreated: json['time'] ?? '', // Moodle suele devolver "hace 5 min"
    );
  }
}