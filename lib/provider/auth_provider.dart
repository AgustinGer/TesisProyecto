// archivo: providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Guardamos el token del usuario
final authTokenProvider = StateProvider<String?>((ref) => null);

// Guardamos el ID del usuario
final userIdProvider = StateProvider<int?>((ref) => null);

//provider de la url
final urlProvider= StateProvider<String?>((ref) => null);

final moodleApiUrlProvider = Provider<String>((ref) {
  // Aquí defines la URL base de tu API en un solo lugar.
  // Cámbiala aquí cuando te conectes a otra red.
  return 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
});