// Puedes crear un archivo models/course.dart
class Course {
  final int id;
  final String fullName;
  final String summary; // La descripción del curso

  Course({
    required this.id,
    required this.fullName,
    required this.summary,
  });

  // Un factory para crear un Course desde el JSON de Moodle
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      fullName: json['fullname'] ?? 'Nombre no disponible',
      // El sumario a veces viene con etiquetas HTML, las quitamos por simplicidad
      summary: (json['summary'] as String? ?? 'Sin descripción')
          .replaceAll(RegExp(r'<[^>]*>'), ''),
    );
  }
}