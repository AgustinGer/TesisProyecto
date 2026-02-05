import 'dart:convert';
import 'package:flutter_tesis/presentation/shared/grade.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importa tu modelo anterior

// Asumo que tienes providers para obtener estos datos básicos.
// Si no, reemplaza esto con cómo obtienes tus credenciales.
// final sessionProvider ... 

final courseGradesProvider =
  FutureProvider.family<List<GradeItem>, ({int courseId, int? userId})>(
    (ref, params) async {

  // --- VALORES DE EJEMPLO (Reemplázalos con tus variables reales) ---
  // ID del usuario logueado en Moodle
  final token = ref.read(authTokenProvider);
  //final userId = ref.read(userIdProvider);
  final baseUrl = ref.read(moodleApiUrlProvider);
  
  final loggedUserId = ref.read(userIdProvider);
  final effectiveUserId = params.userId ?? loggedUserId;
  // ------------------------------------------------------------------

  // 2. Configurar la URL de la función Moodle
  final uri = Uri.parse('$baseUrl/webservice/rest/server.php');

  // 3. Hacer la petición POST
  final response = await http.post(uri, body: {
    'wstoken': token,
    'wsfunction': 'gradereport_user_get_grade_items',
    'moodlewsrestformat': 'json',
    'courseid': params.courseId.toString(),
   // 'userid': userId.toString(), // Importante para ver TUS notas
    'userid': effectiveUserId.toString(),
  });

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);

    // Verificar si Moodle devolvió una excepción
    if (jsonResponse.containsKey('exception')) {
      throw Exception('Error Moodle: ${jsonResponse['message']}');
    }

    // 4. Parsear la respuesta
    // La estructura es: { "usergrades": [ { "courseid": X, "gradeitems": [...] } ] }
    final List<dynamic> userGrades = jsonResponse['usergrades'] ?? [];

    if (userGrades.isEmpty) {
      return []; // No hay datos para este curso
    }

    // Tomamos el primer elemento (ya que filtramos por un solo usuario y curso)
    final List<dynamic> rawItems = userGrades[0]['gradeitems'] ?? [];

    // Convertimos la lista JSON a lista de objetos GradeItem
    return rawItems.map((item) => GradeItem.fromJson(item)).toList();
  } else {
    throw Exception('Error de conexión: ${response.statusCode}');
  }
});