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
  final int userId;
  final String timeCreated;
  final bool approved;
  //final List<DatabaseContent> contents;
  DatabaseEntry({
    required this.id,
    required this.fields,
    required this.userId,
    required this.timeCreated,
    required this.approved,
    //required this.contents,
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

      final value = extractFieldValue(field, content);
      mappedFields[field.name] = value;

    }

    String fullName = json['userfullname'] ?? '';
    if (fullName.isEmpty) {
      fullName = '${json['firstname'] ?? ''} ${json['lastname'] ?? ''}'.trim();
    }

    //print(mappedFields.toString());

    return DatabaseEntry(
      id: json['id'],
      fields: mappedFields,
      userId: json['userid'] ?? 0,
      timeCreated: (json['timecreated'] ?? 0).toString(),
      approved: json['approved'] == true || json['approved'] == 1,
    );
  }
}

// Reemplaza tu función extractFieldValue por esta versión mejorada
String extractFieldValue(DatabaseField field, DatabaseContent content) {
  
  // DEBUG: Para ver qué llega exactamente si algo falla
  // print('Field: ${field.type} | Content: ${content.content} | Content1: ${content.content1}');

  switch (field.type) {
    // --- TEXTOS SIMPLES ---
    case 'text':
    case 'textarea':
    case 'number':
      return content.content;

    // --- SELECCIONES (Radio y Menú) ---
    // Moodle suele guardar el VALOR (texto), no el índice. 
    // Si llega texto, lo mostramos. Si llega número, intentamos buscarlo.
    case 'radiobutton':
    case 'menu':
      return content.content; 

    // --- CASILLAS DE VERIFICACIÓN (Checkbox y Multicheckbox) ---
    case 'checkbox':
      // Checkbox simple (0 o 1)
      return content.content == '1' ? 'Sí' : 'No';
    
    case 'multicheckbox':
      // Moodle guarda selecciones múltiples separadas por "##"
      // Ej: "Opción A##Opción B"
      return content.content.replaceAll('##', ', ');

    // --- FECHAS ---
    case 'date':
      if (content.content.isEmpty || content.content == '0') return '';
      final timestamp = int.tryParse(content.content);
      if (timestamp == null) return content.content; // Si ya viene formateada
      
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      // Formato simple: DD/MM/AAAA
      return "${date.day}/${date.month}/${date.year}";

    // --- URL ---
    case 'url':
      // Content: URL, Content1: Texto del enlace
      final url = content.content;
      final text = content.content1.isNotEmpty ? content.content1 : url;
      if (url.isEmpty) return '';
      // Devolvemos HTML para que el widget flutter_html lo renderice como link
      return '<a href="$url">$text</a>';

    // --- COORDENADAS (LatLong) ---
    case 'latlong':
      // Content: Latitud, Content1: Longitud
      final lat = content.content;
      final long = content.content1;
      if (lat.isEmpty && long.isEmpty) return '';
      return 'Lat: $lat, Long: $long'; // O puedes devolver un link a Google Maps

    // --- ARCHIVOS ---
    case 'file':
      if (content.files.isEmpty) return content.content; // Fallback al nombre
      // Creamos links de descarga para cada archivo
      return content.files.map((f) {
        final name = f['filename'];
        final url = f['fileurl']; // Moodle suele devolver 'fileurl'
        return '<a href="$url">$name</a>';
      }).join('<br/>');

    // --- IMÁGENES (Picture) ---
    case 'picture':
      if (content.files.isEmpty) return content.content;
      // Para imágenes, devolvemos una etiqueta <img> para que se vea la foto
      final fileData = content.files.first;
      final imgUrl = fileData['fileurl'];
      // Añadimos token al url si es necesario, o flutter_html manejará headers si lo configuras
      // Por ahora devolvemos HTML básico
      return '<img src="$imgUrl" style="max-width:100%;" />';

    default:
      return content.content;
  }
}


/*
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
}*/
