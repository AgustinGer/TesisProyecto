import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';

final conversationsProvider = FutureProvider.autoDispose((ref) async {
  final token = ref.read(authTokenProvider);
  final userId = ref.read(userIdProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  final response = await http.post(
    Uri.parse('$apiUrl?wsfunction=core_message_get_conversations&wstoken=$token&moodlewsrestformat=json'),
    body: {'userid': userId.toString()},
  );

  final data = json.decode(response.body);
  return data['conversations'] as List;
});

final chatMessagesProvider = FutureProvider.family.autoDispose<List, int>((ref, conversationId) async {
  final token = ref.read(authTokenProvider);
  final userId = ref.read(userIdProvider);
  final apiUrl = ref.read(moodleApiUrlProvider);

  print('--- INICIANDO CARGA DE MENSAJES ---');
  print('ConvID: $conversationId, UserID: $userId');

  try {
    final response = await http.post(
      Uri.parse('$apiUrl?wsfunction=core_message_get_conversation_messages&wstoken=$token&moodlewsrestformat=json'),
      body: {
        'convid': conversationId.toString(),
        'currentuserid': userId.toString(),
        'limitnum': '50',
       // 'newestmessagesfirst': 'true',
      },
    );

    print('Respuesta del Servidor (Status): ${response.statusCode}');
    print('Cuerpo de la Respuesta: ${response.body}');

    final data = json.decode(response.body);

    // VERIFICACIÓN 1: ¿Moodle devolvió una excepción?
    if (data is Map && data.containsKey('exception')) {
      print('ERROR MOODLE: ${data['message']}');
      throw Exception(data['message']);
    }

    // VERIFICACIÓN 2: ¿Existe la clave "messages" y es una lista?
    if (data['messages'] == null) {
      print('ALERTA: La clave "messages" es NULL. Devolviendo lista vacía.');
      return [];
    }

    final List mensajesRaw = data['messages'];
    print('Mensajes encontrados: ${mensajesRaw.length}');

    return mensajesRaw.reversed.toList();
  } catch (e, stack) {
    print('ERROR CRÍTICO EN PROVIDER: $e');
    print('Stacktrace: $stack');
    rethrow;
  }
});