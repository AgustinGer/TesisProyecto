import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;


class ComentariosDataBaseModal extends ConsumerStatefulWidget {
  final int entryId;     // ID de la entrada (recordid)
  final int moduleId;    // <--- CAMBIO: Usaremos el CMID (igual que en calificar)

  const ComentariosDataBaseModal({
    super.key,
    required this.entryId,
    required this.moduleId, // <--- Lo pedimos aquí
  });

  @override
  ConsumerState<ComentariosDataBaseModal> createState() => _ComentariosDataBaseModalState();
}

class _ComentariosDataBaseModalState extends ConsumerState<ComentariosDataBaseModal> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _cargarComentarios();
  }

  Future<void> _cargarComentarios() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      print('--- Cargando Comentarios ---');
      print('CMID: ${widget.moduleId}, Entry: ${widget.entryId}');

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'core_comment_get_comments',
          'moodlewsrestformat': 'json',
          
          'contextlevel': 'module',           // Nivel Módulo
          'instanceid': widget.moduleId.toString(), // CMID
          'component': 'mod_data',
          'itemid': widget.entryId.toString(),
          'area': 'database_entry',
        },
      );

      print('Resp GetComments: ${response.body}'); // VER RESPUESTA EN CONSOLA

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            if (data is Map && data.containsKey('comments')) {
              _comments = data['comments'];
            } else {
              _comments = [];
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error GetComments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarComentario() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // Quitamos el foco para cerrar el teclado
    FocusScope.of(context).unfocus();

    setState(() => _isSending = true);

    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      print('--- Enviando Comentario ---');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'core_comment_add_comments',
          'moodlewsrestformat': 'json',
          
          // --- CORRECCIÓN: Usar sintaxis de array comments[0] ---
          'comments[0][contextlevel]': 'module',
          'comments[0][instanceid]': widget.moduleId.toString(), // CMID
          'comments[0][component]': 'mod_data',
          'comments[0][itemid]': widget.entryId.toString(),
          'comments[0][area]': 'database_entry',
          'comments[0][content]': text, // El texto del comentario
         /* 'contextlevel': 'module',
          'instanceid': widget.moduleId.toString(), // CMID
          'component': 'mod_data',
          'itemid': widget.entryId.toString(),
          'area': 'database_entry',
          'content': text,*/
        },
      );

      print('Resp AddComment: ${response.body}'); // VER RESPUESTA

      final data = json.decode(response.body);
      print('Respuesta AddComment: $data');
    /*  if (mounted) {
        setState(() => _isSending = false); // APAGAMOS CARGA SIEMPRE

        if (data is Map && data.containsKey('id')) {
          _commentController.clear();
          _cargarComentarios(); // Recargamos la lista
        } else if (data is Map && data.containsKey('exception')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error Moodle: ${data['message']}'), backgroundColor: Colors.red),
          );
        }
      }*/

    if (mounted) {
        setState(() => _isSending = false); // Apagamos el círculo de carga

        // --- CORRECCIÓN AQUÍ ---
        // Moodle devuelve una LISTA con los comentarios creados, no un Mapa.
        bool exito = false;
        
        if (data is List && data.isNotEmpty) {
          // Si es una lista y tiene algo, asumimos éxito
          exito = true;
        } else if (data is Map && data.containsKey('id')) {
          // Por si acaso alguna versión devuelve un mapa
          exito = true;
        }

        if (exito) {
          _commentController.clear();       // Limpiamos el campo de texto
          FocusScope.of(context).unfocus(); // Cerramos el teclado
          _cargarComentarios();             // <--- ESTO RECARGA LA LISTA AUTOMÁTICAMENTE
        } else {
          // Si falló, mostramos error
          String errorMsg = 'Error al enviar';
          if (data is Map && data.containsKey('message')) {
             errorMsg = data['message'];
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }

    } catch (e) {
      print('Error AddComment: $e');
      if (mounted) {
        setState(() => _isSending = false); // APAGAMOS CARGA EN ERROR
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ... (El método _stripHtml y build se mantienen igual, solo verifica el build) ...
  
  // Función auxiliar para limpiar HTML (si la necesitas)
  String _stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  Widget build(BuildContext context) {
    // ... Tu código visual del build ...
    // Asegúrate de usar _isSending para el botón de enviar
     return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          const Text('Comentarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? const Center(child: Text('Sin comentarios.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                         final c = _comments[index];
                         return ListTile(
                           leading: const CircleAvatar(child: Icon(Icons.person)),
                           title: Text(c['fullname'] ?? 'Usuario', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                           subtitle: Text(_stripHtml(c['content'] ?? '')),
                         );
                      },
                    ),
          ),
          
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Escribir comentario...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _isSending ? null : _enviarComentario,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}