// archivo: providers/courses_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import '../models/course.dart';



// 1. Es un FutureProvider simple, ya no es un .family. Devuelve una lista de Cursos.
final coursesProvider = FutureProvider<List<Course>>((ref) async {

  // 2. Lee el token y el ID de los providers de autenticación.
  final token = ref.watch(authTokenProvider);
  final userId = ref.watch(userIdProvider);

  // 3. Si no hay token o ID (el usuario no ha iniciado sesión), no hace nada.
  //    Esto es crucial para evitar errores cuando la app recién arranca.
  if (token == null || userId == null) {
    return []; // Devuelve una lista vacía.
  }

    print('--- VERIFICACIÓN DE DATOS PARA OBTENER CURSOS ---');
  print('Usando Token: $token');
  print('Usando UserID: $userId');
  print('-------------------------------------------');

  const String moodleApiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php'; // Usa tu IP real

  // 4. Su única responsabilidad: llamar a la API para obtener los cursos del usuario.
  final response = await http.post(
    Uri.parse(moodleApiUrl),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'wstoken': token,
      'wsfunction': 'core_enrol_get_users_courses',
      'moodlewsrestformat': 'json',
      'userid': userId.toString(), // El ID del usuario debe ser un String
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Error al obtener los cursos del servidor');
  }

  // Si la respuesta no es un JSON, podría ser un error de PHP en el servidor
  if (!response.headers['content-type']!.contains('application/json')) {
    throw Exception('El servidor no respondió con un JSON. Respuesta: ${response.body}');
  }

  final List<dynamic> coursesData = json.decode(response.body);

  if (coursesData.isEmpty) {
    return []; // Devuelve lista vacía si no está inscrito en cursos.
  }

  // Mapea la respuesta JSON a una lista de objetos Course
  // y filtra el curso de la página principal (que suele tener id: 1)
  final coursesList = coursesData
      .where((courseJson) => courseJson['id'] != 1)
      .map((courseJson) => Course.fromJson(courseJson))
      .toList();

  return coursesList;
});