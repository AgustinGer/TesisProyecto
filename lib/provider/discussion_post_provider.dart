// Crea un nuevo archivo providers/discussion_posts_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
// ... otros imports ...

final discussionPostsProvider = FutureProvider.family<List<dynamic>, int>((ref, discussionId) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('No autenticado');
  
  final moodleApiUrl = ref.watch(moodleApiUrlProvider);

  final response = await http.post(
    Uri.parse(moodleApiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_forum_get_discussion_posts',
      'moodlewsrestformat': 'json',
      'discussionid': discussionId.toString(),
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    print('hola');
    print(response.body);
    // Esta función devuelve un objeto que contiene una lista llamada 'posts'
     if (data.containsKey('posts') && data['posts'] != null) {
      return data['posts'] as List<dynamic>;
    } else {
      return []; // devolvemos lista vacía si no hay posts
    }
  } else {
    throw Exception('Error al cargar los posts de la discusión');
  }
    
    /*    return data['posts'] as List<dynamic>;
      } else {
        throw Exception('Error al cargar los posts de la discusión');
      }*/
});