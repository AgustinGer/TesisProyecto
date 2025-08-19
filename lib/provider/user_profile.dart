// Crea un nuevo archivo, ej: providers/user_profile_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Importa el archivo donde tienes authTokenProvider y userIdProvider
import 'package:flutter_tesis/provider/auth_provider.dart';

// Este provider no recibe parámetros, lee de otros providers.
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  
  // "Observa" el token y el ID del usuario que inició sesión.
  final token = ref.watch(authTokenProvider);
  final userId = ref.watch(userIdProvider);

  // Si no hay sesión, lanza un error para que la UI lo muestre.
  if (token == null || userId == null) {
    throw Exception('Usuario no autenticado.');
  }

  // Tu URL de la API
  //const String apiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
  final apiUrl = ref.watch(moodleApiUrlProvider);
  final response = await http.post(
    Uri.parse(apiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_user_get_users_by_field',
      'moodlewsrestformat': 'json',
      'field': 'id', // Buscamos por ID, es más directo y seguro.
      'values[0]': userId.toString(),
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> userData = json.decode(response.body);
    if (userData.isNotEmpty) {
      // Devuelve el mapa con los datos del primer (y único) usuario encontrado.
      return userData[0];
    } else {
      throw Exception('No se encontró el perfil del usuario.');
    }
  } else {
    throw Exception('Error del servidor al obtener el perfil.');
  }
});