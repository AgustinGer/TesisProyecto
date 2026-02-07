import 'dart:convert';
import 'package:flutter_tesis/presentation/coment_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart'; 


// Provider para leer comentarios (Family: recibe contextId y entryId)
final commentsProvider = FutureProvider.family<List<Comment>, ({int contextId, int entryId})>((ref, args) async {
  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  final response = await http.post(
    Uri.parse(apiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'core_comment_get_comments',
      'moodlewsrestformat': 'json',
      'contextlevel': 'module',
      'instanceid': args.contextId.toString(), // ID del contexto del módulo (cmid)
      'component': 'mod_glossary',
      'itemid': args.entryId.toString(), // ID de la entrada específica
      'area': 'glossary_entry',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // core_comment_get_comments devuelve: { "comments": [...], "count": ... }
    if (data is Map && data.containsKey('comments')) {
      final List list = data['comments'];
      return list.map((e) => Comment.fromJson(e)).toList();
    }
    // Si hay error o está vacío
    return [];
  }
  throw Exception('Error cargando comentarios');
});

// Provider de acciones (Agregar comentario)
final commentActionsProvider = Provider((ref) => CommentActions(ref));

class CommentActions {
  final Ref ref;
  CommentActions(this.ref);

  Future<bool> agregarComentario({required int contextId, required int entryId, required String texto}) async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    print('--- ENVIANDO COMENTARIO ---');
    print('Context ID (CMID): $contextId'); // <--- Verifica que este NO sea igual al Glossary ID
    print('Item ID (Entry ID): $entryId');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'core_comment_add_comments',
          'moodlewsrestformat': 'json',
          'comments[0][contextlevel]': 'module',
          'comments[0][instanceid]': contextId.toString(),
          'comments[0][component]': 'mod_glossary',
          'comments[0][itemid]': entryId.toString(),
          'comments[0][area]': 'glossary_entry',
          'comments[0][content]': texto,
        },
      );

      final data = json.decode(response.body);
      // Si éxito, devuelve una lista con el comentario nuevo
      if (data is List && data.isNotEmpty) return true;
      
      print('Error al comentar: $data');
      return false;
    } catch (e) {
      print('Error red comentario: $e');
      return false;
    }
  }
}