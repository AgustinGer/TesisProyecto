// Crea un nuevo archivo, ej: providers/calendar_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
//import 'package:flutter_tesis/providers/auth_provider.dart';

// Este provider no necesita .family, ya que obtiene todos los eventos del usuario logueado
final calendarEventsProvider = FutureProvider<List<dynamic>>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  const moodleApiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
  
  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_calendar_get_calendar_upcoming_view',
      'moodlewsrestformat': 'json',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    // La API devuelve un objeto que contiene una lista llamada 'events'
    return data['events'] as List<dynamic>;
  } else {
    throw Exception('Error al cargar los eventos del calendario');
  }
});