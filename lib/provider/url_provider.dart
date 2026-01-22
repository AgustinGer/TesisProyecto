import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart'; // Ajusta la ruta
import 'package:http/http.dart' as http;

final urlActionsProvider = Provider((ref) => UrlActions(ref));

class UrlActions {
  final Ref ref;
  UrlActions(this.ref);

  Future<bool> crearUrlMoodle({
    required int courseId,
    required int sectionNumber,
    required String titulo,
    required String linkExterno,
  }) async {
    final String apiUrl = ref.read(moodleApiUrlProvider);
    final String token = ref.read(authTokenProvider)!;

    try {
      print('--- [DEBUG URL] INTENTANDO CREAR ENLACE ---');
      final response = await http.post(
        Uri.parse('$apiUrl/webservice/rest/server.php'),
        body: {
          'wstoken': token,
          'wsfunction': 'core_courseformat_create_module', // Función habilitada
          'moodlewsrestformat': 'json',
          'courseid': courseId.toString(),
          'modname': 'url', // Tipo de módulo: URL
          'targetsectionnum': sectionNumber.toString(), // Clave corregida
        },
      );

      final data = json.decode(response.body);
      print('--- [DEBUG URL] RESPUESTA: $data ---');

      if (data is Map && data.containsKey('cmid')) {
        final int newCmid = data['cmid'];
        // Tras crear el "cascarón", le ponemos el nombre real
        await _configurarNombreUrl(newCmid, titulo);
        return true;
      }
      return false;
    } catch (e) {
      print('Error en provider URL: $e');
      return false;
    }
  }

  Future<void> _configurarNombreUrl(int cmid, String nombre) async {
    final String apiUrl = ref.read(moodleApiUrlProvider);
    final String token = ref.read(authTokenProvider)!;

    await http.post(
      Uri.parse('$apiUrl/webservice/rest/server.php'),
      body: {
        'wstoken': token,
        'wsfunction': 'core_update_inplace_editable', // Función disponible
        'moodlewsrestformat': 'json',
        'component': 'core_course',
        'itemtype': 'moduleitemname',
        'itemid': cmid.toString(),
        'value': nombre,
      },
    );
  }
}