import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';

final ratingActionsProvider = Provider((ref) => RatingActions(ref));

class RatingActions {
  final Ref ref;
  RatingActions(this.ref);

  Future<bool> calificarEntrada({
    required int contextId, // El CMID del módulo (que ya arreglamos)
    required int entryId,   // El ID de la palabra/entrada
    required int rating,    // La nota (0 a 100)
    required int ratedUserId, // El ID del alumno dueño de la entrada
    required int scaleId,
  }) async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

print('--- INTENTO DE CALIFICACIÓN ---');
    print('Context ID: $contextId');
    print('Item ID (Entry): $entryId');
    print('Scale ID: $scaleId');
    print('Rating: $rating');
    print('Rated User ID: $ratedUserId');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'core_rating_add_rating',
          'moodlewsrestformat': 'json',
          'contextlevel': 'module',
          'instanceid': contextId.toString(),
          'component': 'mod_glossary',
          'ratingarea': 'entry',
          'itemid': entryId.toString(),
          //'scaleid': '10', // 10 suele ser la escala numérica predeterminada (0-100)
          'scaleid': scaleId.toString(),
          'rating': rating.toString(),
          'rateduserid': ratedUserId.toString(),
          // 'aggregation': '10', // 10 = Promedio (opcional, Moodle suele detectarlo)
          'aggregation': '1',
        },
      );

print('Respuesta Moodle: ${response.body}'); // <--- MIRAR ESTO EN CONSOLA

      final data = json.decode(response.body);

      // Si tiene éxito, devuelve un objeto con "success": true o el rating actualizado
      if (data is Map && (data.containsKey('success') || data.containsKey('aggregate'))) {
        return true;
      }
      
      if (data.containsKey('exception')) {
        print('Error Moodle Rating: ${data['message']}');
      }
      return false;
    } catch (e) {
      print('Error red rating: $e');
      return false;
    }
  }
}