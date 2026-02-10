import 'package:flutter_tesis/presentation/database_fiel_model.dart';

class DatabaseContent {
  final int fieldId;
  final String content;
  final String content1;
    final List<dynamic> files;

  DatabaseContent({
    required this.fieldId,
    required this.content,
    required this.content1,
    required this.files,
  });

  factory DatabaseContent.fromJson(Map<String, dynamic> json) {
    return DatabaseContent(
      fieldId: json['fieldid'] ?? 0,
      content: json['content'] ?? '',
      content1: json['content1'] ?? '',
      files: json['files'] ?? [],
    );
  }
}

class DatabaseEntry {
  final int id; // ID de la entrada
  final Map<String, String> fields; // nombreCampo → valorHumano
 /* final int userId;
  final String userFullName;
  final String timeCreated;
  final List<DatabaseContent> contents; // Los campos llenos
*/
  DatabaseEntry({
    required this.id,
    required this.fields,
  /*  required this.userId,
    required this.userFullName,
    required this.timeCreated,
    required this.contents,*/
  });
    
  factory DatabaseEntry.fromJson(
    Map<String, dynamic> json,
    List<DatabaseField> databaseFields,
  ) {
    final Map<String, String> mappedFields = {};

    final contents = json['contents'] as List? ?? [];

    for (final c in contents) {
      final content = DatabaseContent.fromJson(c);

      // Buscar la definición del campo
      final field = databaseFields.firstWhere(
        (f) => f.id == content.fieldId,
        orElse: () => DatabaseField(
          id: content.fieldId,
          name: 'Campo ${content.fieldId}',
          type: 'text',
          description: '',
          required: false,
          options: const [],
        ),
      );

    /*  String value = content.content;

      // 🔹 Si es select / radio / menu, traducimos el índice
      if (field.options.isNotEmpty) {
        final index = int.tryParse(content.content);
        if (index != null && index >= 0 && index < field.options.length) {
          value = field.options[index];
        }
      }

      mappedFields[field.name] = value;*/
      final value = extractFieldValue(field, content);

      if (value.isNotEmpty) {
        mappedFields[field.name] = value;
      }

    }

    return DatabaseEntry(
      id: json['id'],
      fields: mappedFields,
    );
  }
}

String extractFieldValue(DatabaseField field, DatabaseContent content) {
  switch (field.type) {
    case 'text':
    case 'textarea':
    case 'radiobutton':
      return content.content;

    case 'url':
      return content.content1;

    case 'date':
      if (content.content.isEmpty) return '';
      final timestamp = int.tryParse(content.content);
      if (timestamp == null) return '';
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          .toLocal()
          .toString()
          .split(' ')
          .first;

    case 'checkbox':
      return content.content == '1' ? 'Sí' : 'No';

    case 'menu':
      final index = int.tryParse(content.content) ?? -1;
      if (index >= 0 && index < field.options.length) {
        return field.options[index];
      }
      return '';

    case 'file':
      return content.files.isNotEmpty
          ? content.files.map((f) => f['filename']).join(', ')
          : '';

    default:
      return content.content;
  }
}
