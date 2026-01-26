import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../provider/auth_provider.dart';

// Provider para obtener los detalles de la entrega del alumno
final submissionDetailsProvider = FutureProvider.family<Map<String, dynamic>, ({int assignId, int userId})>((ref, arg) async {
  final apiUrl = ref.read(moodleApiUrlProvider);
  final token = ref.read(authTokenProvider)!;

  final response = await http.post(Uri.parse(apiUrl), body: {
    'wstoken': token,
    'wsfunction': 'mod_assign_get_submission_status',
    'moodlewsrestformat': 'json',
    'assignid': arg.assignId.toString(),
    'userid': arg.userId.toString(),
  });

  final data = json.decode(response.body);
  if (data is Map && data.containsKey('exception')) throw Exception(data['message']);
  return data;
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
  }) async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final token = ref.read(authTokenProvider)!;

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {
        'wstoken': token,
        'wsfunction': 'mod_assign_save_grade',
        'moodlewsrestformat': 'json',
        'assignmentid': assignId.toString(),
        'userid': userId.toString(),
        'grade': nota.toString(),
        'attemptnumber': "-1", // Último intento
        'addattempt': "0",
        'workflowstate': "graded",
        'applytoall': "0",
      });

      return !response.body.contains('exception');
    } catch (e) {
      return false;
    }
  }
}