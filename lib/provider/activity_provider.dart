//import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
//import 'package:flutter_tesis/providers/auth_provider.dart';

const String moodleApiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';

// PROVIDER 1: Obtiene los detalles de la tarea (nombre, descripción, fecha)
final assignmentDetailsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, int>>((ref, ids) async {
  print('--- VERIFICADOR: assignmentDetailsProvider INICIADO ---');
  final token = ref.watch(authTokenProvider);
  final courseId = ids['courseId']!;
  final assignmentId = ids['assignmentId']!;

  if (token == null) throw Exception('No autenticado');

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