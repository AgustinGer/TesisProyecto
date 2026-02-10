import 'dart:convert';
import 'package:flutter_tesis/presentation/database_model.dart';
import 'package:flutter_tesis/provider/database_actions_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';


// Provider para obtener las entradas de la base de datos
final databaseEntriesProvider = FutureProvider.family<List<DatabaseEntry>, int>((ref, databaseId) async {
  final token = ref.read(authTokenProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  // 🔹 1. Obtener los fields (definición)
  final fields = await ref.read(
    databaseFieldsProvider(databaseId).future,
  );

  final response = await http.post(
    Uri.parse(apiUrl),
    body: {
      'wstoken': token,
      'wsfunction': 'mod_data_get_entries',
      'moodlewsrestformat': 'json',
      'databaseid': databaseId.toString(),
      'returncontents': '1', // Importante para que devuelva los valores
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    // Moodle devuelve: { "entries": [...], "totalcount": ... }
    if (data is Map && data.containsKey('entries')) {
      final List list = data['entries'];
      return list.map((e) => DatabaseEntry.fromJson(e,fields)).toList();
    } 
    
    if (data is Map && data.containsKey('exception')) {
      throw Exception(data['message']);
    }
  }
  return [];
});