import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../provider/auth_provider.dart'; // Ajusta a tu ruta real


// Cambiamos la definición del parámetro arg
final studentSubmissionsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({int courseId, int assignId})>((ref, arg) async {
  final courseId = arg.courseId; // Ahora accedemos así
  final assignId = arg.assignId;
  final apiUrl = ref.read(moodleApiUrlProvider);
  final token = ref.read(authTokenProvider)!;

  try {
    print('--- [DEBUG] Petición única para Tarea ID: $assignId ---');

    final usersRes = await http.post(Uri.parse(apiUrl), body: {
      'wstoken': token,
      'wsfunction': 'core_enrol_get_enrolled_users',
      'moodlewsrestformat': 'json',
      'courseid': courseId.toString(),
    });

    final subsRes = await http.post(Uri.parse(apiUrl), body: {
      'wstoken': token,
      'wsfunction': 'mod_assign_get_submissions',
      'moodlewsrestformat': 'json',
      'assignmentids[0]': assignId.toString(),
    });

    final dynamic usersData = json.decode(usersRes.body);
    final dynamic subsData = json.decode(subsRes.body);

    if (usersData is Map && usersData.containsKey('exception')) throw Exception(usersData['message']);
    if (subsData is Map && subsData.containsKey('exception')) throw Exception(subsData['message']);

    final List allUsers = usersData as List;
    final List assignments = subsData['assignments'] ?? [];
    final List submissions = assignments.isNotEmpty ? (assignments[0]['submissions'] ?? []) : [];

    final Set<int> submittedUserIds = submissions
        .where((s) => s['status'] == 'submitted')
        .map((s) => s['userid'] as int)
        .toSet();

    return allUsers.where((user) {
      final roles = user['roles'] as List;
      return roles.any((r) => r['shortname'] == 'student');
    }).map((user) {
      return {
        'id': user['id'],
        'fullname': user['fullname'],
        'profileimageurl': user['profileimageurl'],
        'hasSubmitted': submittedUserIds.contains(user['id']),
      };
    }).toList();

  } catch (e) {
    print('Error en provider: $e');
    rethrow;
  }
});