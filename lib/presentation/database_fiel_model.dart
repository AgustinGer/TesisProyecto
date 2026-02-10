//import 'dart:convert';

class DatabaseField {
  final int id;
  final String name;
  final String type; // 'text', 'number', 'textarea', 'date', etc.
   final List<String> options;
  final String description;
  final bool required;

  // NUEVO: Capturamos el parámetro que contiene las opciones (para menús, radios, etc.)
  //final String param1;

  DatabaseField({
    required this.id,
    required this.name,
    required this.type,
     required this.options,
    required this.description,
    required this.required,

    //required this.param1,
  });

  factory DatabaseField.fromJson(Map<String, dynamic> json) {
    return DatabaseField(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'] ?? '', // 👈 NUNCA null
      required: json['required'] == 1,        // 👈 INT → BOOL

      options: (json['param1'] ?? '')
          .toString()
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList(),
    
    //  description: json['description'] ?? '',
    //  required: json['required'] == 1,
    //  param1: json['param1'] ?? '',
    );
  }

  // Helper para obtener las opciones como lista
  /*List<String> get options {
    if (param1.isEmpty) return [];
    // Moodle separa las opciones por salto de línea (\n o \r\n)
    return const LineSplitter().convert(param1).where((s) => s.trim().isNotEmpty).toList();
  }*/
}