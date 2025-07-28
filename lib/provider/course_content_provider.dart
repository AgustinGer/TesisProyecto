// Crea un archivo providers/course_content_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Asume que tienes modelos para Section, Module, etc. o usa Map<String, dynamic>

// Usamos .family para pasarle el ID del curso
final courseContentProvider = FutureProvider.family<List<dynamic>, int>((ref, courseId) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  const moodleApiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
  
  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_course_get_contents',
      'moodlewsrestformat': 'json',
      'courseid': courseId.toString(),
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> courseContents = json.decode(response.body);
    return courseContents;
  } else {
    throw Exception('Error al cargar el contenido del curso');
  }
});