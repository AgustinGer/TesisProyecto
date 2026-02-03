import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tesis/provider/auth_provider.dart'; // Importa tus proveedores de IP y Token

// Creamos un provider para acceder a las acciones del curso
final courseActionsProvider = Provider((ref) => CourseActions(ref));

class CourseActions {
  final Ref ref;
  CourseActions(this.ref);

  /// Función oficial para Moodle 4.5 usando Course Format API
  Future<bool> crearSeccionMoodle(int courseId, int targetSectionId) async {
  final String apiUrl = ref.read(moodleApiUrlProvider); 
  final String token = ref.read(authTokenProvider)!;

  try {
    final response = await http.post(
      Uri.parse('$apiUrl/webservice/rest/server.php'),
      body: {
        'wstoken': token,
        'wsfunction': 'core_courseformat_update_course',
        'moodlewsrestformat': 'json',
        'courseid': courseId.toString(),
        'action': 'section_add',
        'targetsectionid': targetSectionId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // ÉXITO: Moodle 4.5 devuelve una LISTA de cambios realizados
      if (data is List) return true; 
      
      // Si devuelve un mapa, verificamos que no sea una excepción
      if (data is Map && data.containsKey('exception')) {
        print('Error Moodle: ${data['message']}');
        return false;
      }
      return true;
    }
    return false;
  } catch (e) {
    print('Error de conexión: $e');
    return false;
  }
}


/*Future<bool> editarNombreSeccion(int sectionId, String nuevoNombre) async {
  final String apiUrl = ref.read(moodleApiUrlProvider); 
  final String token = ref.read(authTokenProvider)!;

  try {
    final response = await http.post(
      Uri.parse('$apiUrl/webservice/rest/server.php'),
      body: {
        'wstoken': token,
        'wsfunction': 'core_course_edit_section',
        'moodlewsrestformat': 'json',
        'id': sectionId.toString(), // CAMBIO: Debe ser 'id' según la API de Moodle
        'action': 'setname',
        'value': nuevoNombre,
      },
    );
    print('Respuesta Renombrado (Raw): ${response.body}');
    
    if (response.statusCode == 200) {
      final String body = response.body;
      
      // Moodle devuelve un error dentro de un 200 OK si hay excepciones
      if (body.contains('exception')) {
        return false;
      }
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}*/
Future<bool> editarNombreSeccion(int sectionId, String nuevoNombre) async {
  final String apiUrl = ref.read(moodleApiUrlProvider); 
  final String token = ref.read(authTokenProvider)!;

  try {
    final response = await http.post(
      Uri.parse('$apiUrl/webservice/rest/server.php'),
      body: {
        'wstoken': token,
        'wsfunction': 'core_update_inplace_editable',
        'moodlewsrestformat': 'json',
        'component': 'format_topics', // O 'format_weeks' según tu curso
        'itemtype': 'sectionname',
        'itemid': sectionId.toString(),
        'value': nuevoNombre,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Moodle devuelve el objeto actualizado si tiene éxito
      return data != null && !response.body.contains('exception');
    }
    return false;
  } catch (e) {
    return false;
  }
}

// Dentro de tu clase CourseActions
Future<bool> editarUrlMoodle({
  required int moduleId, 
  required String nuevoNombre, 
  required String nuevaUrl
}) async {
  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'core_course_edit_module', // Función estándar para editar módulos
        'moodlewsrestformat': 'json',
        'id': moduleId.toString(),
        'action': 'edit',
        'name': nuevoNombre,
        // Para el caso de URL, Moodle suele requerir campos específicos del plugin
        // Si 'core_course_edit_module' no te permite cambiar la URL directamente, 
        // se usa 'mod_url_update_url' (depende de los permisos de tu token).
      },
    );

    final data = json.decode(response.body);
    
    if (data is Map && data.containsKey('exception')) {
      print('Error Moodle: ${data['message']}');
      return false;
    }

    return true; // Éxito
  } catch (e) {
    print('Error de red: $e');
    return false;
  }
 }


 Future<bool> enviarMensaje({required int userIdTo, required String texto}) async {
  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  print('--- INTENTANDO ENVIAR MENSAJE ---');
  print('Para UserID: $userIdTo | Texto: $texto');

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'core_message_send_instant_messages',
        'moodlewsrestformat': 'json',
        // Estructura obligatoria de Moodle para arreglos:
        'messages[0][touserid]': userIdTo.toString(),
        'messages[0][text]': texto,
        'messages[0][textformat]': '1', // 1 = HTML, suele ser el más compatible
      },
    );

    print('Respuesta Enviar Mensaje (Status): ${response.statusCode}');
    print('Cuerpo Respuesta Enviar: ${response.body}');

    final data = json.decode(response.body);

    if (data is List && data.isNotEmpty) {
      // Moodle devuelve una lista de mensajes enviados si tiene éxito
      if (data[0].containsKey('msgid')) {
        print('✅ Mensaje enviado con éxito. ID: ${data[0]['msgid']}');
        return true;
      }
    }
    
    if (data is Map && data.containsKey('exception')) {
      print('Error Moodle al enviar: ${data['message']}');
    }

    return false;
  } catch (e) {
    print(' Error de red al enviar: $e');
    return false;
  }
}
 
}

