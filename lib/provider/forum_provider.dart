// Crea un nuevo archivo providers/forum_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;


// Usamos .family para pasarle el ID del foro
final forumDiscussionsProvider = FutureProvider.family<List<dynamic>, int>((ref, forumId) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');

  //const moodleApiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
  final moodleApiUrl = ref.watch(moodleApiUrlProvider);
  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_forum_get_forum_discussions',
      'moodlewsrestformat': 'json',
      'forumid': forumId.toString(),
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    // La API devuelve un objeto que contiene una lista llamada 'discussions'
    return data['discussions'] as List<dynamic>;
  } else {
    throw Exception('Error al cargar las discusiones del foro');
  }
});