import 'dart:convert';
import 'package:flutter_tesis/presentation/database_fiel_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';


// 1. Provider para traer la estructura del formulario
/// 1. Provider para traer campos
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

  // Función auxiliar para "curar" opciones (arregla mayúsculas/espacios)
  String _matchOption(String value, DatabaseField field) {
    // Si el campo tiene opciones (Radio, Menu, Checkbox)
    if (field.options.isNotEmpty) {
      // Buscamos si existe una opción igual ignorando mayúsculas/espacios
      for (var opt in field.options) {
        if (opt.trim().toLowerCase() == value.trim().toLowerCase()) {
          print('Auto-corrección: "${value}" -> "${opt}"');
          return opt; // Devolvemos la opción EXACTA de Moodle
        }
      }
    }
    return value; // Si no hay match, devolvemos el valor original
  }

  Future<bool> agregarEntrada({
    required int databaseId,
    required Map<int, String> values, 
    required List<DatabaseField> fields, 
  }) async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    print('--- ENVIANDO DATOS CURADOS ---');

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
        orElse: () => DatabaseField(
          id: 0,
          name: '',
          type: 'text',
        /*  description: '',
          required: false,
          param1: '',*/
            description: '',
          required: false,
          options: const [],
          
        ),
      );

      String finalValue = rawValue;

      if (field.type == 'radiobutton' || field.type == 'menu') {
        finalValue = _matchOption(rawValue, field);
      }

      print('Campo ${field.name} (${field.type}) -> "$finalValue"');

  
        body['data[$index][fieldid]'] = fieldId.toString();

        // 👇 SUBFIELD OBLIGATORIO
        if (field.type == 'file' || field.type == 'picture') {
          body['data[$index][subfield]'] = 'file';
        } else {
          body['data[$index][subfield]'] = '';
        }

        body['data[$index][value]'] = finalValue;
        index++;


    });


    try {
      final response = await http.post(Uri.parse(apiUrl), body: body);
      final data = json.decode(response.body);

      print('Respuesta Moodle: $data');

      if (data is Map && data['newentryid'] != null) {
        int newId = int.tryParse(data['newentryid'].toString()) ?? 0;
        if (newId > 0) return true;
        
        print('Error Moodle: ${data['generalnotifications']}');
      }
      return false;
    } catch (e) {
      print('Error red: $e');
      return false;
    }
  }
}


String resolveRadioValue(DatabaseField field, String content) {
  final index = int.tryParse(content);
  if (index == null) return content;

  final options = field.options; // animal, persona
  if (index >= 0 && index < options.length) {
    return options[index];
  }
  return content;
}

/*class DatabaseActions {
  final Ref ref;
  DatabaseActions(this.ref);

  Future<bool> agregarEntrada({
    required int databaseId,
    required Map<int, String> values, // Mapa: ID del campo -> Valor ingresado
  }) async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    // CONSTRUCCIÓN DINÁMICA DEL BODY
    // Moodle espera: data[0][fieldid]=X, data[0][value]=Y, data[1][fieldid]=...
    final Map<String, String> body = {
      'wstoken': token!,
      'wsfunction': 'mod_data_add_entry',
      'moodlewsrestformat': 'json',
      'databaseid': databaseId.toString(),
    };

    int index = 0;
    values.forEach((fieldId, value) {
      body['data[$index][fieldid]'] = fieldId.toString();
      body['data[$index][value]'] = value;
      index++;
    });

    try {
      final response = await http.post(Uri.parse(apiUrl), body: body);
      final data = json.decode(response.body);

      // Moodle devuelve { "newentryid": 123, ... } si es exitoso
      if (data is Map && data.containsKey('newentryid')) {
        return true;
      }
      print('Error Moodle Database: $data');
      return false;
    } catch (e) {
      print('Error red: $e');
      return false;
    }
  }
}*/