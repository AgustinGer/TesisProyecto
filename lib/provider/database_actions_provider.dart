import 'dart:convert';
import 'package:flutter_tesis/presentation/database_fiel_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';



final databaseFieldsProvider = FutureProvider.family<List<DatabaseField>, int>((ref, databaseId) async {
  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  final response = await http.post(Uri.parse(apiUrl), body: {
    'wstoken': token,
    'wsfunction': 'mod_data_get_fields',
    'moodlewsrestformat': 'json',
    'databaseid': databaseId.toString(),
  });

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data is Map && data.containsKey('fields')) {
      final List list = data['fields'];
      return list.map((e) => DatabaseField.fromJson(e)).toList();
    }
  }
  return [];
});

final databaseActionsProvider = Provider((ref) => DatabaseActions(ref));

class DatabaseActions {
  final Ref ref;
  DatabaseActions(this.ref);

  // Función para corregir mayúsculas/espacios automáticamente
  String _matchOption(String value, DatabaseField field) {
    // Limpiamos el valor de entrada primero
    final cleanValue = value.trim();
    
    if (field.options.isNotEmpty) {
      for (var opt in field.options) {
        // Comparamos ignorando mayúsculas y espacios
        if (opt.trim().toLowerCase() == cleanValue.toLowerCase()) {
          return opt.trim(); // Devolvemos la opción EXACTA de Moodle limpia
        }
      }
    }
    return cleanValue; 
  }

  Future<bool> agregarEntrada({
    required int databaseId,
    required Map<int, String> values, 
    required List<DatabaseField> fields, 
  }) async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    print('--- ENVIANDO DATOS LIMPIOS Y TRIMMED ---');

    final Map<String, String> body = {
      'wstoken': token!,
      'wsfunction': 'mod_data_add_entry',
      'moodlewsrestformat': 'json',
      'databaseid': databaseId.toString(),
    };

    int index = 0;
    
    values.forEach((fieldId, rawValue) {
      final field = fields.firstWhere(
        (f) => f.id == fieldId, 
        orElse: () => DatabaseField(id: 0, name: '', type: 'text', description: '', required: false, options: const []),
      );

      // 1. LIMPIEZA CRÍTICA: .trim() elimina el \n que está rompiendo tu app
      String finalValue = rawValue.trim(); 

      // 2. Corregimos opciones (Radio/Menu/Checkbox)
      if (['radiobutton', 'menu', 'checkbox'].contains(field.type)) {
         finalValue = _matchOption(finalValue, field);
      }

      // LOG: Verifica que las comillas cierren en la misma línea
      print('Campo ${field.name} (${field.type}) -> "$finalValue"');

      // 3. Construcción del Body
      body['data[$index][fieldid]'] = fieldId.toString();
      body['data[$index][value]'] = finalValue;

      // 4. LÓGICA DE SUBFIELD (EXTREMADAMENTE IMPORTANTE)
      // Moodle borra el texto si envías subfield='' (vacío).
      // SOLO debemos enviarlo si es un archivo o coordenada.

      if (field.type == 'file' || field.type == 'picture') {
        body['data[$index][subfield]'] = '0'; // 0 = Archivo adjunto
      } 
      else if (field.type == 'latlong') {
        body['data[$index][subfield]'] = '0'; // Latitud
      }
      
      // ¡NO AGREGUES NADA MÁS AQUÍ! 
      // Si el campo es 'text', 'number', 'radio', NO se envía la clave subfield.

      index++;
    });

    try {
      final response = await http.post(Uri.parse(apiUrl), body: body);
      final data = json.decode(response.body);

      print('Respuesta Moodle: $data');

      if (data is Map && data['newentryid'] != null) {
        int newId = int.tryParse(data['newentryid'].toString()) ?? 0;
        if (newId > 0) return true;
        
        print('Error Moodle (ID=0): ${data['generalnotifications']}');
      }
      return false;
    } catch (e) {
      print('Error red: $e');
      return false;
    }
  }
}
