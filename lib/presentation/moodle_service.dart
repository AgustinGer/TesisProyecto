import 'dart:convert';
import 'package:http/http.dart' as http;

Future<bool> checkIsAdmin({
  required String apiUrl,
  required String token,
}) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_webservice_get_site_info',
      'moodlewsrestformat': 'json',
    },
  );

  final data = json.decode(response.body);

  if (data['exception'] != null) {
    throw Exception(data['message']);
  }

  return data['isadmin'] ?? false;
}

Future<String> getUserRoleInCourse({
  required String apiUrl,
  required String token,
  required int courseId,
  required int userId,
}) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_enrol_get_enrolled_users',
      'moodlewsrestformat': 'json',
      'courseid': courseId.toString(),
    },
  );

  final users = json.decode(response.body) as List;

  final user = users.firstWhere(
    (u) => u['id'] == userId,
    orElse: () => null,
  );

  if (user == null) return 'student';

  for (final role in user['roles']) {
    switch (role['shortname']) {
      case 'manager':
        return 'manager';
      case 'editingteacher':
        return 'editingteacher';
      case 'teacher':
        return 'teacher';
      case 'student':
        return 'student';
    }
  }

  return 'student';
}
