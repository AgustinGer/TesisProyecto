import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart'; // Tu provider de auth


/*
class DatabaseConfig {
  final int id;
  final int scale; 
  final bool ratingsEnabled;

  DatabaseConfig({required this.id, required this.scale, required this.ratingsEnabled});
}

// Definimos los tipos explícitamente <DatabaseConfig, Map<String, int>>
final databaseConfigProvider = FutureProvider.family<DatabaseConfig, Map<String, int>>((ref, params) async {
  
 // print('🔵 [ConfigProvider] Iniciando...');
  
  // 1. Extraer y verificar parámetros
  final courseId = params['courseId'];
  final databaseInstanceId = params['databaseId'];

  //print('🔵 [ConfigProvider] Params recibidos -> CourseID: $courseId, DB_ID: $databaseInstanceId');

  if (courseId == null || databaseInstanceId == null) {
    print('🔴 [ConfigProvider] Error: IDs nulos');
    throw Exception("CourseID o DatabaseID son nulos");
  }

  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  if (token == null || apiUrl.isEmpty) {
     print('🔴 [ConfigProvider] Error: Token o URL vacíos');
     throw Exception("No hay token o API URL");
  }

  try {
    // 2. Hacer la petición a Moodle
    //print('🔵 [ConfigProvider] Consultando API: mod_data_get_databases_by_courses');
    
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'mod_data_get_databases_by_courses',
        'moodlewsrestformat': 'json',
        'courseids[0]': courseId.toString(),
      },
    );

   // print('🔵 [ConfigProvider] Respuesta HTTP: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Verificar si Moodle devolvió una excepción
      if (data is Map && data.containsKey('exception')) {
     //   print('🔴 [ConfigProvider] Excepción Moodle: ${data['message']}');
        throw Exception(data['message']);
      }

      if (data is Map && data.containsKey('databases')) {
        final List dbs = data['databases'];
        //print('🔵 [ConfigProvider] Bases de datos encontradas en el curso: ${dbs.length}');

        // 3. Buscar la base de datos actual (CONVERSIÓN SEGURA A STRING)
        // Convertimos ambos a String para evitar error de "int vs String"
        final currentDb = dbs.firstWhere(
          (db) => db['id'].toString() == databaseInstanceId.toString(),
          orElse: () => null,
        );

        if (currentDb != null) {
          final int scale = int.tryParse(currentDb['scale'].toString()) ?? 0;
          final bool enabled = scale != 0; 
          
          //print('✅ [ConfigProvider] Config encontrada! Scale: $scale, Enabled: $enabled');

          return DatabaseConfig(
            id: int.parse(currentDb['id'].toString()),
            scale: scale.abs(), 
            ratingsEnabled: enabled, 
          );
        } else {
          print('⚠️ [ConfigProvider] No se encontró la DB con ID $databaseInstanceId en la lista.');
        }
      } else {
        print('⚠️ [ConfigProvider] No vino la lista "databases" en el JSON.');
      }
    } else {
      print('🔴 [ConfigProvider] Error de red: ${response.statusCode}');
    }
  } catch (e, stack) {
    print('🔴 [ConfigProvider] ERROR FATAL: $e');
    print(stack);
    rethrow; // Re-lanzamos el error para que la UI lo detecte
  }

  // Configuración por defecto si falla algo
  print('⚠️ [ConfigProvider] Retornando config por defecto (Sin calificación)');
  return DatabaseConfig(id: 0, scale: 0, ratingsEnabled: false);
});*/

class DatabaseConfig {
  final int id;
  final int scale;
  final bool ratingsEnabled;

  DatabaseConfig({required this.id, required this.scale, required this.ratingsEnabled});
}

// CAMBIO IMPORTANTE: Ahora recibimos un String (ej: "2-4") en lugar de un Mapa
final databaseConfigProvider = FutureProvider.family<DatabaseConfig, String>((ref, uniqueKey) async {
  
  // 1. Separamos el string "CursoID-BaseDatosID"
  final parts = uniqueKey.split('-');
  if (parts.length != 2) return DatabaseConfig(id: 0, scale: 0, ratingsEnabled: false);

  final courseId = parts[0];
  final databaseInstanceId = parts[1];

  print('🔵 [ConfigProvider] Cargando config una sola vez para: $uniqueKey'); 

  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  if (token == null) return DatabaseConfig(id: 0, scale: 0, ratingsEnabled: false);

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'mod_data_get_databases_by_courses',
        'moodlewsrestformat': 'json',
        'courseids[0]': courseId,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is Map && data.containsKey('databases')) {
        final List dbs = data['databases'];
        
        // Buscamos la base de datos correcta
        final currentDb = dbs.firstWhere(
          (db) => db['id'].toString() == databaseInstanceId,
          orElse: () => null,
        );

        if (currentDb != null) {
          final int scale = int.tryParse(currentDb['scale'].toString()) ?? 0;
          print('✅ Config encontrada. Scale: $scale');
          return DatabaseConfig(
            id: int.parse(currentDb['id'].toString()),
            scale: scale.abs(), 
            ratingsEnabled: scale != 0, 
          );
        }
      }
    }
  } catch (e) {
    print('Error Provider: $e');
  }
  return DatabaseConfig(id: 0, scale: 0, ratingsEnabled: false);
});