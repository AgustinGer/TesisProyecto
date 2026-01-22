
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart'; // Asegura que la ruta sea correcta
import 'package:http/http.dart' as http;

// 1. Definimos el Provider para que pueda ser usado en los widgets
final assignActionsProvider = Provider((ref) => AssignActions(ref));

class AssignActions {
  final Ref ref;
  AssignActions(this.ref);

 Future<bool> crearTareaMoodle({
  required int courseId,
  required int sectionNumber,
  required String nombre,
}) async {
  final String apiUrl = ref.read(moodleApiUrlProvider);
  final String token = ref.read(authTokenProvider)!;

  try {
    print('--- [DEBUG TAREA] INTENTANDO CREACIÓN ---');
    final response = await http.post(
      Uri.parse('$apiUrl/webservice/rest/server.php'),
      body: {
        'wstoken': token,
        'wsfunction': 'core_courseformat_create_module', // Función habilitada
        'moodlewsrestformat': 'json',
        'courseid': courseId.toString(),
        'modname': 'assign', 
        'targetsectionnum': sectionNumber.toString(),
      },
    );

    final data = json.decode(response.body);
    print('--- [DEBUG TAREA] RESPUESTA SERVIDOR: $data ---');

    // CASO A: Moodle creó el módulo y devolvió el ID (Éxito)
    if (data is Map && data.containsKey('cmid')) {
      final int newCmid = data['cmid'];
      print('--- [DEBUG TAREA] CMID GENERADO: $newCmid. PROCEDIENDO A RENOMBRAR... ---');
      
      // Intentamos poner el nombre real usando la función disponible
      await _renombrarTarea(newCmid, nombre);
      return true;
    }
    
    // CASO B: Moodle lanzó error pero quizás el módulo existe
    if (data is Map && data.containsKey('exception')) {
      print('--- [DEBUG TAREA] EXCEPCIÓN DETECTADA: ${data['message']} ---');
      print('CONSEJO: Revisa tu Moodle en el navegador. ¿Apareció una "Nueva Tarea" en la sección $sectionNumber?');
    }
    
    return false;
  } catch (e) {
    print('--- [DEBUG TAREA] ERROR CRÍTICO DE RED: $e ---');
    return false;
  }
}

Future<void> _renombrarTarea(int cmid, String nombre) async {
  final String apiUrl = ref.read(moodleApiUrlProvider);
  final String token = ref.read(authTokenProvider)!;

  final response = await http.post(
    Uri.parse('$apiUrl/webservice/rest/server.php'),
    body: {
      'wstoken': token,
      'wsfunction': 'core_update_inplace_editable', // Tienes esta función
      'moodlewsrestformat': 'json',
      'component': 'core_course',
      'itemtype': 'moduleitemname',
      'itemid': cmid.toString(),
      'value': nombre,
    },
  );
  print('--- [DEBUG TAREA] RESULTADO RENOMBRADO: ${response.body} ---');
}

}