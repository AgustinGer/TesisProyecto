// Crea un archivo providers/courses_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/course.dart'; // Importa tu modelo

final coursesProvider = FutureProvider.family<List<Course>, Map<String, String>>((ref, params) async {
  final token = params['token']!;
  final email = params['email']!;

  const moodleApiUrl = 'https://192.168.1.45/tesismovil/webservice/rest/server.php';
  
  // --- PASO 1: Obtener el ID del Usuario ---
  final userResponse = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_user_get_users_by_field',
      'moodlewsrestformat': 'json',
      'field': 'email',
      'values[0]': email,
    },
  );

  if (userResponse.statusCode != 200) {
    throw Exception('Error al obtener datos del usuario');
  }

  final userData = json.decode(userResponse.body);
  if (userData['users'] == null || (userData['users'] as List).isEmpty) {
    throw Exception('Usuario no encontrado');
  }
  final userId = userData['users'][0]['id'].toString();

  // --- PASO 2: Obtener los Cursos del Usuario ---
  final coursesResponse = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_enrol_get_users_courses',
      'moodlewsrestformat': 'json',
      'userid': userId,
    },
  );

  if (coursesResponse.statusCode != 200) {
    throw Exception('Error al obtener los cursos');
  }

  final List coursesData = json.decode(coursesResponse.body);
  if (coursesData.isEmpty) {
    return []; // Devuelve una lista vacía si el usuario no tiene cursos
  }

  // Filtramos el curso de la página principal (id: 1)
  final coursesList = coursesData
      .where((courseJson) => courseJson['id'] != 1) 
      .map((courseJson) => Course.fromJson(courseJson))
      .toList();

  return coursesList;
});