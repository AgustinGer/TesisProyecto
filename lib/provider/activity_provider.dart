//import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;

//import 'package:flutter_tesis/providers/auth_provider.dart';

const String moodleApiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';

final assignmentDetailsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, int>>((ref, ids) async {
  print('--- VERIFICADOR: assignmentDetailsProvider INICIADO ---');
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  int courseId = ids['courseId'] ?? 0;
  int assignmentId = ids['assignmentId']!;

  // Verificar si el ID que recibimos es en realidad un cmid y no un assignmentid
  final moduleResponse = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_course_get_course_module',
      'moodlewsrestformat': 'json',
      'cmid': assignmentId.toString(),
    },
  );

  final moduleData = json.decode(moduleResponse.body);

  // Si la respuesta tiene datos de módulo y es de tipo "assign", corregimos IDs
  if (moduleData is Map && moduleData.containsKey('cm') && moduleData['cm']['modname'] == 'assign') {
    print('--- INFO: ID recibido era cmid, corrigiendo a assignmentid real ---');
    assignmentId = moduleData['cm']['instance']; // ID real de la tarea
    courseId = moduleData['cm']['course'];       // ID real del curso
  } else {
    print('--- INFO: ID recibido ya es assignmentid real ---');
  }

  // Llamar a mod_assign_get_assignments para obtener la lista de tareas
  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_assignments',
      'moodlewsrestformat': 'json',
      'courseids[0]': courseId.toString(),
    },
  ).timeout(const Duration(seconds: 20));
 print(courseId);
  print('--- VERIFICADOR: Respuesta de get_assignments RECIBIDA ---');
  final data = json.decode(response.body);
  if (data is Map && data.containsKey('exception')) {
    throw Exception('Error de Moodle: ${data['message']}');
  }

  final courses = data['courses'] as List? ?? [];
  if (courses.isEmpty) throw Exception('Curso no encontrado');

  final assignments = courses[0]['assignments'] as List? ?? [];
  final assignmentDetails = assignments.firstWhere(
    (a) => a['id'] == assignmentId,
    orElse: () => throw Exception('Tarea no encontrada en la lista'),
  );

  print('--- VERIFICADOR: assignmentDetailsProvider COMPLETADO ---');
  return assignmentDetails;
});


final submissionStatusProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, assignmentId) async {
  //print('');
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_submission_status',
      'moodlewsrestformat': 'json',
      'assignid': assignmentId.toString(),
    },
  ).timeout(const Duration(seconds: 20));
  
  print(assignmentId);
  print('--- VERIFICADOR: Respuesta de get_submission_status RECIBIDA ---');
  final data = json.decode(response.body);
  if (data is Map && data.containsKey('exception')) {
    throw Exception('Error de Moodle: ${data['message']}');
  }

  print('--- VERIFICADOR: submissionStatusProvider COMPLETADO ---');
  return data;
});



// En tu archivo providers/activity_provider.dart
/*
final submissionStatusProviderCalendario = FutureProvider.family<Map<String, dynamic>, int>((ref, cmid) async {
  print('--- VERIFICADOR: submissionStatusProvider INICIADO con cmid: $cmid ---');
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  // --- PASO 1: Usamos el cmid para obtener el ID real de la tarea (assignmentid) ---
  final moduleResponse = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_course_get_course_module',
      'moodlewsrestformat': 'json',
      'cmid': cmid.toString(),
    },
  ).timeout(const Duration(seconds: 20));
  
  if (moduleResponse.statusCode != 200) throw Exception('Error al buscar el módulo del curso');
  
  final moduleData = json.decode(moduleResponse.body);
  if (moduleData.containsKey('exception')) {
    throw Exception('Error de Moodle al buscar el módulo: ${moduleData['message']}');
  }

  // Extraemos el ID real de la tarea de la respuesta
  final int assignmentId = moduleData['cm']['instance']; 
  print('--- INFO: ID real de la tarea obtenido: $assignmentId ---');

  // --- PASO 2: Ahora sí, llamamos a la API con el ID correcto ---
  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_submission_status',
      'moodlewsrestformat': 'json',
      'assignid': assignmentId.toString(), // <-- Usamos el ID real y correcto
    },
  ).timeout(const Duration(seconds: 20));
  
  print('--- VERIFICADOR: Respuesta de get_submission_status RECIBIDA ---');
  final data = json.decode(response.body);
  if (data is Map && data.containsKey('exception')) {
    throw Exception('Error de Moodle al obtener estado: ${data['message']}');
  }

  print('--- VERIFICADOR: submissionStatusProvider COMPLETADO ---');
  return data;
});

*/

/*
final submissionStatusProviderCalendario = 
    FutureProvider.family<int, int>((ref, cmid) async {
  print('--- VERIFICADOR: submissionStatusProviderCalendario INICIADO con cmid: $cmid ---');

  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  // --- Paso 1: Usamos el cmid para obtener el ID real de la tarea (assignmentId) ---
  final moduleResponse = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_course_get_course_module',
      'moodlewsrestformat': 'json',
      'cmid': cmid.toString(),
    },
  ).timeout(const Duration(seconds: 20));

  if (moduleResponse.statusCode != 200) {
    throw Exception('Error al buscar el módulo del curso');
  }

  final moduleData = json.decode(moduleResponse.body);
  if (moduleData.containsKey('exception')) {
    throw Exception('Error de Moodle al buscar el módulo: ${moduleData['message']}');
  }

  // Extraemos el ID real de la tarea
  final int assignmentId = moduleData['cm']['instance'];
  return assignmentId; // <-- Esto es un int
});

*/
/*

// Provider para obtener el estado de la entrega
final submissionStatusProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
   final token = ref.watch(authTokenProvider);
  final courseId = params['courseId'] as int;
  final assignmentId = params['assignmentId'] as int;

  // Primero usamos el provider anterior para obtener el assignmentid real
  final details = await ref.watch(assignmentDetailsProvider({
    'courseId': courseId,
    'assignmentId': assignmentId,
  }).future);

  final realAssignmentId = details['id'];

  // Llamar al WS para obtener el estado de la entrega
  final statusResponse = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_submission_status',
      'moodlewsrestformat': 'json',
      'assignid': realAssignmentId.toString(),
    },
  ).timeout(const Duration(seconds: 20));
  final statusData = jsonDecode(statusResponse.body);

    if (statusData is Map && statusData.containsKey('status')) {
      return Map<String, dynamic>.from(statusData);
    } else {
      throw Exception(
          'No se pudo obtener el estado de la entrega para el assignmentid $realAssignmentId');
    }
});

*/

/*

// PROVIDER 2: Obtiene el estado de la entrega del usuario
final submissionStatusProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, assignmentId) async {
  print('--- VERIFICADOR: submissionStatusProvider INICIADO ---');
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_submission_status',
      'moodlewsrestformat': 'json',
      'assignid': assignmentId.toString(),
    },
  ).timeout(const Duration(seconds: 20));
  
  print('--- VERIFICADOR: Respuesta de get_submission_status RECIBIDA ---');
  final data = json.decode(response.body);
  if (data is Map && data.containsKey('exception')) {
    throw Exception('Error de Moodle: ${data['message']}');
  }

  print('--- VERIFICADOR: submissionStatusProvider COMPLETADO ---');
  return data;
});

*/
/*
// PROVIDER 1: Obtiene los detalles de la tarea (nombre, descripción, fecha)
final assignmentDetailsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, int>>((ref, ids) async {
  print('--- VERIFICADOR: assignmentDetailsProvider INICIADO ---');
  final token = ref.watch(authTokenProvider);
  //final courseId = ids['courseId']!;
  int? courseId = ids['courseId'];
  final assignmentId = ids['assignmentId']!;

  if (token == null) throw Exception('No autenticado');

   if (courseId == null) {
    final moduleResponse = await http.post(
      Uri.parse(moodleApiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'core_course_get_course_module',
        'moodlewsrestformat': 'json',
        'cmid': assignmentId.toString(), // cmid es el ID de la tarea que sí tenemos
      },
    );
    final moduleData = json.decode(moduleResponse.body);
    courseId = moduleData['cm']['course'];
  }

  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_assignments',
      'moodlewsrestformat': 'json',
      'courseids[0]': courseId.toString(),
    },
  ).timeout(const Duration(seconds: 20));

  print('--- VERIFICADOR: Respuesta de get_assignments RECIBIDA ---');
  final data = json.decode(response.body);
  if (data is Map && data.containsKey('exception')) {
    throw Exception('Error de Moodle: ${data['message']}');
  }

  final courses = data['courses'] as List? ?? [];
  if (courses.isEmpty) throw Exception('Curso no encontrado');

  final assignments = courses[0]['assignments'] as List? ?? [];
  final assignmentDetails = assignments.firstWhere(
    (a) => a['id'] == assignmentId,
    orElse: () => throw Exception('Tarea no encontrada en la lista'),
  );

  print('--- VERIFICADOR: assignmentDetailsProvider COMPLETADO ---');
  return assignmentDetails;
});

**/