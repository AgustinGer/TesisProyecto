
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/moodle_service.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';

final userRole = FutureProvider.family<String, int>((ref, courseId) async {
  final apiUrl = ref.watch(moodleApiUrlProvider);
  final token = ref.watch(authTokenProvider);
  final userId = ref.watch(userIdProvider);

  if (token == null || userId == null) {
    throw Exception('Usuario no autenticado');
  }

  // 1️⃣ Admin global
  final isAdmin = await checkIsAdmin(
    apiUrl: apiUrl,
    token: token,
  );

  if (isAdmin) return 'admin';

  // 2️⃣ Rol dentro del curso
  return await getUserRoleInCourse(
    apiUrl: apiUrl,
    token: token,
    courseId: courseId,
    userId: userId,
  );
});
