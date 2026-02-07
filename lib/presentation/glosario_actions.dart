import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart'; // Ajusta tus imports

final glossaryActionsProvider = Provider((ref) => GlossaryActions(ref));

class GlossaryActions {
  final Ref ref;
  GlossaryActions(this.ref);

  Future<bool> agregarEntrada({
    required int glossaryId,
    required String concepto,
    required String definicion,
    int? attachmentId, // El ID de los archivos subidos (draftItemId)
  }) async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final Map<String, String> body = {
        'wstoken': token!,
        'wsfunction': 'mod_glossary_add_entry',
        'moodlewsrestformat': 'json',
        'glossaryid': glossaryId.toString(),
        'concept': concepto,
        'definition': definicion,
        'definitionformat': '1', // 1 = HTML
      };

      // Si hay archivos adjuntos, los añadimos a las opciones
      if (attachmentId != null) {
        body['options[0][name]'] = 'attachmentsid';
        body['options[0][value]'] = attachmentId.toString();
      }

      final response = await http.post(Uri.parse(apiUrl), body: body);
      final data = json.decode(response.body);

      if (data is Map && data.containsKey('entryid')) {
        return true; // Éxito
      } else {
        print('Error Moodle: $data');
        return false;
      }
    } catch (e) {
      print('Error de red: $e');
      return false;
    }
  }
}