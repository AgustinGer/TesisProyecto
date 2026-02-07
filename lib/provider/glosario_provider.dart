import 'dart:convert';
import 'package:flutter_tesis/presentation/glosario_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart'; 

final glossaryEntriesProvider = FutureProvider.family<List<GlossaryEntry>, int>((ref, glossaryInstanceId) async {
  
  // Usamos tus providers para obtener URL y Token
  final apiUrl = ref.read(moodleApiUrlProvider); 
  final token = ref.read(authTokenProvider);

  if (token == null) throw Exception("Token no encontrado");

  final response = await http.post(
    Uri.parse(apiUrl), // Usamos la URL directa del provider
    body: {
      'wstoken': token,
      'wsfunction': 'mod_glossary_get_entries_by_search', // Función clave
      'moodlewsrestformat': 'json',
      'id': glossaryInstanceId.toString(), // ID de la instancia del glosario
      'query': '', // Vacío para traer TODOS los términos
      'limit': '100', // Límite de carga
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);

    // Moodle devuelve la lista dentro de la llave "entries"
    if (jsonResponse.containsKey('entries')) {
      final List<dynamic> entriesRaw = jsonResponse['entries'];
      return entriesRaw.map((e) => GlossaryEntry.fromJson(e)).toList();
    } else if (jsonResponse.containsKey('exception')) {
      throw Exception('Error Moodle: ${jsonResponse['message']}');
    }
    // Si no hay entradas, devuelve lista vacía
    return [];
  } else {
    throw Exception('Error de conexión HTTP: ${response.statusCode}');
  }
});


// Provider para saber si se permiten comentarios
final glossaryConfigProvider = FutureProvider.family<bool, ({int courseId, int glossaryId})>((ref, args) async {
  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  final response = await http.post(
    Uri.parse(apiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_glossary_get_glossaries_by_courses',
      'moodlewsrestformat': 'json',
      'courseids[0]': args.courseId.toString(),
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // Moodle devuelve: { "glossaries": [ ... ] }
    if (data is Map && data.containsKey('glossaries')) {
      final List glossaries = data['glossaries'];
      
      // Buscamos nuestro glosario específico en la lista
      final myGlossary = glossaries.firstWhere(
        (g) => g['id'] == args.glossaryId, 
        orElse: () => null
      );

      if (myGlossary != null) {
        // allowcomments: 1 = habilitado, 0 = deshabilitado
        return myGlossary['allowcomments'] == 1;
      }
    }
  }
  return false; // Por defecto asumimos que NO se puede comentar si falla
});