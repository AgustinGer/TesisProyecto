// archivo: providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Guardamos el token del usuario
final authTokenProvider = StateProvider<String?>((ref) => null);

// Guardamos el ID del usuario
final userIdProvider = StateProvider<int?>((ref) => null);

//provider de la url
final urlProvider= StateProvider<String?>((ref) => null);


final moodleBaseUrlProvider = Provider<String>((ref) {
  return 'http://192.168.1.45/tesismovil';
});

final moodleApiUrlProvider = Provider<String>((ref) {
  // Aquí defines la URL base de tu API en un solo lugar.
  // Cámbiala aquí cuando te conectes a otra red.
  return 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
});

// ¿Es administrador?
final isAdminProvider = StateProvider<bool>((ref) => false);

// Rol del usuario en el curso actual
final userCourseRoleProvider = StateProvider<String?>((ref) => null);

final localRatingsCacheProvider = StateProvider<Map<int, String>>((ref) => {});


// --- NUEVA FUNCIÓN PARA RECUPERAR SESIÓN ---
Future<bool> checkSavedSession(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('user_token');
  final userId = prefs.getInt('user_id');
  final isAdmin = prefs.getBool('is_admin') ?? false;

  if (token != null && userId != null) {
    // Si hay datos, restauramos la sesión en Riverpod
    ref.read(authTokenProvider.notifier).state = token;
    ref.read(userIdProvider.notifier).state = userId;
    ref.read(isAdminProvider.notifier).state = isAdmin;

    
    
    // Asignamos la URL por defecto (o puedes guardarla también en SharedPreferences si cambia mucho)
    ref.read(urlProvider.notifier).state = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
    
    return true; // Hay sesión activa
  }
  return false; // No hay sesión, debe ir al Login
}