// archivo: providers/assignment_provider.dart

// El provider ahora recibe un Mapa con ambos IDs
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;



final assignmentProvider = FutureProvider.family<Map<String, dynamic>, Map<String, int>>((ref, ids) async {
  final token = ref.watch(authTokenProvider);
  final courseId = ids['courseId']!;
  final assignmentId = ids['assignmentId']!;

  if (token == null) throw Exception('No autenticado');
  const moodleApiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
  
  // --- LLAMADA 1: Obtener detalles de TODAS las tareas del curso ---
  final assignmentsResponse = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_assignments',
      'moodlewsrestformat': 'json',
      'courseids[0]': courseId.toString(), // <-- Usamos el ID del curso
    },
  );
  if (assignmentsResponse.statusCode != 200) throw Exception('Error al cargar datos de la tarea');
  
  final assignmentsData = json.decode(assignmentsResponse.body);
  final coursesList = assignmentsData['courses'] as List<dynamic>? ?? [];
  if (coursesList.isEmpty) throw Exception('No se encontró el curso para esta tarea.');
  
  final assignmentsList = coursesList[0]['assignments'] as List<dynamic>? ?? [];
  if (assignmentsList.isEmpty) throw Exception('No se encontraron tareas en este curso.');

  // --- Filtramos para encontrar NUESTRA tarea específica ---
  final assignmentDetails = assignmentsList.firstWhere(
    (assign) => assign['id'] == assignmentId,
    orElse: () => throw Exception('Detalles de la tarea no encontrados'),
  );

  // --- LLAMADA 2: Obtener el estado de la entrega (esta parte estaba bien) ---
  // ... (el código para llamar a mod_assign_get_submission_status no cambia) ...
 final statusResponse = await http.post(
  Uri.parse(moodleApiUrl),
  body: {
    'wstoken': token,
    'wsfunction': 'mod_assign_get_submission_status',
    'moodlewsrestformat': 'json',
    'assignid': assignmentId.toString(),
  },
);

if (statusResponse.statusCode != 200) {
    throw Exception('Error al cargar estado de la entrega');
}
  final statusData = json.decode(statusResponse.body);
  final submissionStatus = statusData['lastattempt']?['submission']?['status'] ?? 'No entregado';

  // --- PASO 3: Combinar los resultados ---
  return {
    'name': assignmentDetails['name'],
    'intro': assignmentDetails['intro'],
    'duedate': assignmentDetails['duedate'],
    'status': submissionStatus,
  };
});