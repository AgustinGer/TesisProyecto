import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../provider/auth_provider.dart';

// Provider para obtener los detalles de la entrega del alumno
final submissionDetailsProvider = FutureProvider.family<Map<String, dynamic>, ({int assignId, int userId})>((ref, arg) async {
  final apiUrl = ref.read(moodleApiUrlProvider);
  final token = ref.read(authTokenProvider)!;

  try {
    print('--- [DEBUG CALIFICAR] Consultando Tarea: ${arg.assignId} para Usuario: ${arg.userId} ---');

    final response = await http.post(Uri.parse(apiUrl), body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_submission_status',
      'moodlewsrestformat': 'json',
      'assignid': arg.assignId.toString(),
      'userid': arg.userId.toString(),
    });

    print('--- [DEBUG CALIFICAR] Respuesta: ${response.body} ---');

    final data = json.decode(response.body);
    
    if (data is Map && data.containsKey('exception')) {
      throw Exception('Moodle dice: ${data['message']}');
    }
    
    return data;
  } catch (e) {
    print('Error crítico en submissionDetailsProvider: $e');
    rethrow;
  }
});

// Clase para las acciones de calificar
final gradeActionsProvider = Provider((ref) => GradeActions(ref));

class GradeActions {
  final Ref ref;
  GradeActions(this.ref);

  Future<bool> guardarNota({
    required int assignId,
    required int userId,
    required double nota,
    String? feedback, // Nuevo parámetro opcional
  }) async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final token = ref.read(authTokenProvider)!;

    try {
      // Preparamos el cuerpo básico
      final Map<String, String> body = {
        'wstoken': token,
        'wsfunction': 'mod_assign_save_grade',
        'moodlewsrestformat': 'json',
        'assignmentid': assignId.toString(),
        'userid': userId.toString(),
        'grade': nota.toString(),
        'attemptnumber': "-1",
        'addattempt': "0",
        'workflowstate': "graded",
        'applytoall': "0",
      };

      // Si hay feedback, lo añadimos siguiendo el formato de Moodle
      if (feedback != null && feedback.trim().isNotEmpty) {
        body['plugindata[assignfeedbackcomments_editor][text]'] = feedback;
        body['plugindata[assignfeedbackcomments_editor][format]'] = "1"; // Formato HTML/Texto
      }

      final response = await http.post(Uri.parse(apiUrl), body: body);
      print('Respuesta Calificación: ${response.body}');

      return !response.body.contains('exception');
    } catch (e) {
      print('Error al guardar nota: $e');
      return false;
    }
  }


}