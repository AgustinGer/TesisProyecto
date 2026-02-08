// Basado en tu archivo 1, pero filtrando PROFESORES
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';

final courseTeachersProvider = FutureProvider.family<List<int>, int>((ref, courseId) async {
  
  final apiUrl = ref.read(moodleApiUrlProvider);
  final token = ref.read(authTokenProvider)!;

  // 1. Llamamos a la misma función que usas para traer estudiantes
  final response = await http.post(Uri.parse(apiUrl), body: {
    'wstoken': token,
    'wsfunction': 'core_enrol_get_enrolled_users', // Trae a TODOS
    'moodlewsrestformat': 'json',
    'courseid': courseId.toString(),
  });

  final dynamic data = json.decode(response.body);

  if (data is Map && data.containsKey('exception')) {
    throw Exception(data['message']);
  }

  final List users = data as List;
  final List<int> teacherIds = [];

  // 2. Recorremos los usuarios
  for (var user in users) {
    final List roles = user['roles'] ?? [];
    
    // 3. CAMBIO CLAVE: Verificamos si tiene roles de autoridad
    final isTeacher = roles.any((r) {
      final shortname = r['shortname'];
      return shortname == 'editingteacher' || 
             shortname == 'teacher' || 
             shortname == 'manager' || 
             shortname == 'admin'; 
    });

    // 4. Si es profesor, guardamos su ID
    if (isTeacher) {
      teacherIds.add(user['id']);
    }
  }

  return teacherIds;
});