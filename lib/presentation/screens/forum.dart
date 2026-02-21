import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import 'package:url_launcher/url_launcher.dart';
//import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//import 'package:dio/dio.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//import 'package:open_filex/open_filex.dart';

/*

class ForumScreen extends ConsumerStatefulWidget {
  final int instanceId;
  final int courseId;
  final int cmid;
  final String title;

  const ForumScreen({
    super.key,
    required this.instanceId,
    required this.courseId,
    required this.cmid,
    required this.title,
  });

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _forumData;
  List<dynamic> _discussions = [];
  String? _errorMessage;

  // Controladores para el formulario de nuevo tema
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- CARGA DE DATOS ---
  Future<void> _cargarTodo() async {
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      await _cargarInfoForo(apiUrl);
      await _cargarMensajes(apiUrl);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Error de conexión: Verifica tu internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarInfoForo(String apiUrl) async {
    final token = ref.read(authTokenProvider);
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'mod_forum_get_forums_by_courses',
        'moodlewsrestformat': 'json',
        'courseids[0]': widget.courseId.toString(),
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('forums')) {
        final List forums = data['forums'];
        final myForum = forums.firstWhere((f) => f['id'] == widget.instanceId, orElse: () => null);
        if (myForum != null && mounted) setState(() => _forumData = myForum);
      }
    }
  }

  Future<void> _cargarMensajes(String apiUrl) async {
    final token = ref.read(authTokenProvider);
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'mod_forum_get_forum_discussions',
        'moodlewsrestformat': 'json',
        'forumid': widget.instanceId.toString(),
        'sortorder': '1',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('discussions')) {
        if (mounted) setState(() => _discussions = data['discussions']);
      }
    }
  }

  // --- ENVIAR NUEVO TEMA ---
  Future<void> _enviarNuevoTema() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa el asunto y el mensaje"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isSending = true);
    Navigator.pop(context); // Cerramos el diálogo primero

    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_forum_add_discussion',
          'moodlewsrestformat': 'json',
          'forumid': widget.instanceId.toString(),
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      final data = json.decode(response.body);

      if (data is Map && data.containsKey('discussionid')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Tema publicado con éxito!"), backgroundColor: Colors.green)
        );
        _subjectController.clear();
        _messageController.clear();
        
        // Recargar para mostrar el nuevo tema
        setState(() => _isLoading = true);
        await _cargarTodo(); 
      } else {
        String errorMsg = data['message'] ?? "Error desconocido";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $errorMsg"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión al enviar."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // --- DIÁLOGO DE NUEVO TEMA (MEJORADO) ---
  void _mostrarDialogoNuevoTema() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.add_comment_rounded, color: Colors.indigo.shade400),
              const SizedBox(width: 10),
              const Expanded(child: Text("Nuevo Tema", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Inicia una nueva conversación en este foro.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 15),
                TextField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: "Asunto",
                    hintText: "Ej: Duda sobre el proyecto",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: "Mensaje",
                    hintText: "Escribe tu consulta o aporte aquí...",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 15, bottom: 15),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _enviarNuevoTema,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text("Publicar"),
            ),
          ],
        );
      },
    );
  }

  // --- HELPERS ---
  String _formatDate(int? timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  void _onLinkTapped(String? url) async {
    if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo gris suave para contrastar tarjetas
      appBar: AppBar(
        title: const Text('Foro de Discusión'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: (_isLoading || _isSending) 
            ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo))
            : null,
      ),
      // BOTÓN FLOTANTE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoTema,
        label: const Text("Nuevo Tema", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_comment_rounded),
        backgroundColor: Colors.indigo,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- TÍTULO Y DESCRIPCIÓN DEL FORO ---
                  Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),

                  if (_forumData != null && _forumData!['intro'] != null && _forumData!['intro'].toString().isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Html(
                        data: _forumData!['intro'],
                        style: {"body": Style(fontSize: FontSize(15.0), margin: Margins.zero, color: Colors.black87)},
                        onLinkTap: (url, _, __) => _onLinkTapped(url),
                        extensions: [
                           TagExtension(
                            tagsToExtend: {"img"},
                            builder: (ctx) {
                              String src = ctx.element?.attributes['src'] ?? "";
                              if (src.contains('pluginfile.php')) { src = src.contains('?') ? '$src&token=$token' : '$src?token=$token'; }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(src, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey))
                              );
                            },
                          ),
                        ]
                      ),
                    ),
                  
                  const SizedBox(height: 25),
                  
                  // --- ENCABEZADO DE LISTA ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Temas de Discusión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      Chip(
                        label: Text("${_discussions.length}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.indigo.shade50,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- LISTA DE DISCUSIONES ---
                  if (_errorMessage != null)
                     Container(
                       padding: const EdgeInsets.all(15),
                       decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                       child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800)),
                     )
                  else if (_discussions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                              child: Icon(Icons.forum_rounded, size: 50, color: Colors.indigo.shade200),
                            ),
                            const SizedBox(height: 15),
                            const Text("Aún no hay temas de discusión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 5),
                            const Text("Sé el primero en iniciar una conversación.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _discussions.length,
                      itemBuilder: (context, index) {
                        final disc = _discussions[index];
                        final subject = disc['subject'] ?? "Sin Asunto";
                        final author = disc['userfullname'] ?? "Anónimo";
                        final authorPic = disc['userpictureurl']; // URL de la foto de Moodle
                        final message = disc['message'] ?? ""; 
                        final date = _formatDate(disc['created']);
                        final replyCount = disc['numreplies'] ?? 0; // Contador de respuestas
                        final id = disc['discussion'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.push(
                                  '/forum/discussion',
                                  extra: {
                                    'discussionId': id,
                                    'subject': subject,
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Título del tema
                                    Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                    const SizedBox(height: 12),
                                    
                                    // Info del Autor
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.indigo.shade100,
                                          backgroundImage: authorPic != null ? NetworkImage(authorPic) : null,
                                          child: authorPic == null ? const Icon(Icons.person, size: 16, color: Colors.indigo) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(author, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                                              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                    
                                    // Vista previa del mensaje (limpiando HTML)
                                    Text(
                                      message.replaceAll(RegExp(r'<[^>]*>'), '').trim(), 
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Pie de la tarjeta (Respuestas y Acción)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey.shade500),
                                            const SizedBox(width: 5),
                                            Text(
                                              replyCount == 1 ? "1 respuesta" : "$replyCount respuestas", 
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("Ver debate", style: TextStyle(color: Colors.indigo.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.indigo.shade600),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Espacio para que el FAB no tape el último item
                ],
              ),
            ),
    );
  }
}*/

class ForumScreen extends ConsumerStatefulWidget {
  final int instanceId;
  final int courseId;
  final int cmid;
  final String title;

  const ForumScreen({
    super.key,
    required this.instanceId,
    required this.courseId,
    required this.cmid,
    required this.title,
  });

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _forumData;
  List<dynamic> _discussions = [];
  String? _errorMessage;

  // Controladores para el formulario de nuevo tema
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- CARGA DE DATOS ---
  Future<void> _cargarTodo() async {
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      await _cargarInfoForo(apiUrl);
      await _cargarMensajes(apiUrl);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Error de conexión: Verifica tu internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarInfoForo(String apiUrl) async {
    final token = ref.read(authTokenProvider);
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'mod_forum_get_forums_by_courses',
        'moodlewsrestformat': 'json',
        'courseids[0]': widget.courseId.toString(),
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('forums')) {
        final List forums = data['forums'];
        final myForum = forums.firstWhere((f) => f['id'] == widget.instanceId, orElse: () => null);
        if (myForum != null && mounted) setState(() => _forumData = myForum);
      }
    }
  }

  Future<void> _cargarMensajes(String apiUrl) async {
    final token = ref.read(authTokenProvider);
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'mod_forum_get_forum_discussions',
        'moodlewsrestformat': 'json',
        'forumid': widget.instanceId.toString(),
        'sortorder': '1',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data.containsKey('discussions')) {
        if (mounted) setState(() => _discussions = data['discussions']);
      }
    }
  }

  // --- ENVIAR NUEVO TEMA ---
  Future<void> _enviarNuevoTema() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa el asunto y el mensaje"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isSending = true);
    Navigator.pop(context);

    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_forum_add_discussion',
          'moodlewsrestformat': 'json',
          'forumid': widget.instanceId.toString(),
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      final data = json.decode(response.body);

      if (data is Map && data.containsKey('discussionid')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Tema publicado con éxito!"), backgroundColor: Colors.green)
        );
        _subjectController.clear();
        _messageController.clear();
        
        setState(() => _isLoading = true);
        await _cargarTodo(); 
      } else {
        String errorMsg = data['message'] ?? "Error desconocido";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $errorMsg"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión al enviar."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // --- ABRIR FORO EN LA WEB ---
  Future<void> _abrirForoWeb() async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    // Usamos el cmid del foro para abrirlo directamente
    final url = '$baseUrl/mod/forum/view.php?id=${widget.cmid}';
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir: $e')));
      }
    }
  }

  // --- WIDGET BOTÓN MULTIMEDIA EXTERNO ---
  Widget _buildExternalContentButton(String? url, String label, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange.shade800, size: 30),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          const Text("Visualización web recomendada", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text("Ver en Navegador"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              if (url != null && url.isNotEmpty) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } else {
                _abrirForoWeb(); // Abre la página general del foro
              }
            },
          )
        ],
      ),
    );
  }

  // --- DIÁLOGO DE NUEVO TEMA ---
  void _mostrarDialogoNuevoTema() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.add_comment_rounded, color: Colors.indigo.shade400),
              const SizedBox(width: 10),
              const Expanded(child: Text("Nuevo Tema", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Inicia una nueva conversación en este foro.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 15),
                TextField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: "Asunto",
                    hintText: "Ej: Duda sobre el proyecto",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: "Mensaje",
                    hintText: "Escribe tu consulta o aporte aquí...",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 15, bottom: 15),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _enviarNuevoTema,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text("Publicar"),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  void _onLinkTapped(String? url) async {
    if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Foro de Discusión'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Abrir en navegador',
            onPressed: _abrirForoWeb,
          ),
        ],
        bottom: (_isLoading || _isSending) 
            ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo))
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoTema,
        label: const Text("Nuevo Tema", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_comment_rounded),
        backgroundColor: Colors.indigo,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- TÍTULO Y DESCRIPCIÓN DEL FORO ---
                  Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),

                  if (_forumData != null && _forumData!['intro'] != null && _forumData!['intro'].toString().isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Html(
                        data: _forumData!['intro'],
                        style: {
                          "body": Style(fontSize: FontSize(15.0), margin: Margins.zero, color: Colors.black87),
                          "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
                          "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
                          "video": Style(height: Height(200), width: Width(100, Unit.percent)),
                        },
                        onLinkTap: (url, _, __) => _onLinkTapped(url),
                        extensions: [
                          TagExtension(
                            tagsToExtend: {"table"},
                            builder: (extensionContext) => _buildExternalContentButton(null, "Tabla de Datos Compleja", Icons.table_chart_rounded),
                          ),
                          TagExtension(
                            tagsToExtend: {"audio"},
                            builder: (extensionContext) {
                               final element = extensionContext.element;
                               String src = element?.attributes['src'] ?? "";
                               if (src.isEmpty && element != null) {
                                for (var child in element.children) {
                                  if (child.localName == 'source') src = child.attributes['src'] ?? "";
                                }
                              }
                              return _buildExternalContentButton(src.isNotEmpty ? src : null, "Audio / Grabación", Icons.audiotrack_rounded);
                            },
                          ),
                          TagExtension(
                            tagsToExtend: {"video"},
                            builder: (extensionContext) {
                              final element = extensionContext.element;
                              String src = element?.attributes['src'] ?? "";
                              if (src.isEmpty && element != null) {
                                for (var child in element.children) {
                                  if (child.localName == 'source') src = child.attributes['src'] ?? "";
                                }
                              }
                              if (src.isNotEmpty && YoutubePlayer.convertUrlToId(src) != null) {
                                return EmbeddedYoutubePlayer(url: src);
                              }
                              return _buildExternalContentButton(src, "Video Formato Web", Icons.videocam_off);
                            },
                          ),
                          TagExtension(
                            tagsToExtend: {"iframe"},
                            builder: (extensionContext) {
                              final element = extensionContext.element;
                              String src = element?.attributes['src'] ?? "";
                              if (src.startsWith('//')) src = 'https:$src';
                              if (YoutubePlayer.convertUrlToId(src) != null) {
                                return EmbeddedYoutubePlayer(url: src);
                              }
                              return _buildExternalContentButton(src, "Contenido Interactivo", Icons.touch_app);
                            },
                          ),
                          TagExtension(
                            tagsToExtend: {"math"},
                            builder: (extensionContext) => _buildExternalContentButton(null, "Ecuación Matemática", Icons.functions_rounded),
                          ),
                          TagExtension(
                            tagsToExtend: {"time"},
                            builder: (extensionContext) {
                              final dateText = extensionContext.element?.text ?? "Fecha";
                              return _buildExternalContentButton(null, "Dato de Tiempo: $dateText", Icons.access_time_filled_rounded);
                            },
                          ),
                          TagExtension(
                            tagsToExtend: {"object", "embed"},
                            builder: (extensionContext) {
                              final element = extensionContext.element;
                              String src = element?.attributes['src'] ?? element?.attributes['data'] ?? "";
                              return _buildExternalContentButton(src.isNotEmpty ? src : null, "Objeto Multimedia", Icons.extension_rounded);
                            },
                          ),
                          TagExtension(
                            tagsToExtend: {"form", "input", "button"},
                            builder: (extensionContext) => _buildExternalContentButton(null, "Elemento Interactivo", Icons.touch_app_rounded),
                          ),
                          TagExtension(
                            tagsToExtend: {"img"},
                            builder: (ctx) {
                              String src = ctx.element?.attributes['src'] ?? "";
                              if (src.contains('pluginfile.php') && !src.contains('token=')) { 
                                src = src.contains('?') ? '$src&token=$token' : '$src?token=$token'; 
                              }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(src, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey))
                              );
                            },
                          ),
                        ]
                      ),
                    ),
                  
                  const SizedBox(height: 25),
                  
                  // --- ENCABEZADO DE LISTA ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Temas de Discusión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      Chip(
                        label: Text("${_discussions.length}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.indigo.shade50,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- LISTA DE DISCUSIONES ---
                  if (_errorMessage != null)
                     Container(
                       padding: const EdgeInsets.all(15),
                       decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                       child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800)),
                     )
                  else if (_discussions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                              child: Icon(Icons.forum_rounded, size: 50, color: Colors.indigo.shade200),
                            ),
                            const SizedBox(height: 15),
                            const Text("Aún no hay temas de discusión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 5),
                            const Text("Sé el primero en iniciar una conversación.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _discussions.length,
                      itemBuilder: (context, index) {
                        final disc = _discussions[index];
                        final subject = disc['subject'] ?? "Sin Asunto";
                        final author = disc['userfullname'] ?? "Anónimo";
                        final authorPic = disc['userpictureurl']; 
                        final message = disc['message'] ?? ""; 
                        final date = _formatDate(disc['created']);
                        final replyCount = disc['numreplies'] ?? 0; 
                        final id = disc['discussion'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.push(
                                  '/forum/discussion',
                                  extra: {
                                    'discussionId': id,
                                    'subject': subject,
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.indigo.shade100,
                                          backgroundImage: authorPic != null ? NetworkImage(authorPic) : null,
                                          child: authorPic == null ? const Icon(Icons.person, size: 16, color: Colors.indigo) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(author, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                                              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                    
                                    Text(
                                      message.replaceAll(RegExp(r'<[^>]*>'), '').trim(), 
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey.shade500),
                                            const SizedBox(width: 5),
                                            Text(
                                              replyCount == 1 ? "1 respuesta" : "$replyCount respuestas", 
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("Ver debate", style: TextStyle(color: Colors.indigo.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.indigo.shade600),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

// --- CLASE PARA YOUTUBE ---
class EmbeddedYoutubePlayer extends StatefulWidget {
  final String url;
  const EmbeddedYoutubePlayer({super.key, required this.url});
  @override
  State<EmbeddedYoutubePlayer> createState() => _EmbeddedYoutubePlayerState();
}

class _EmbeddedYoutubePlayerState extends State<EmbeddedYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.url);
    if (videoId != null) {
      _isValid = true;
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false, enableCaption: false),
      );
    }
  }

  @override
  void dispose() {
    if (_isValid) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValid) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          bottomActions: [
            CurrentPosition(),
            ProgressBar(isExpanded: true),
            RemainingDuration(),
          ],
        ),
      ),
    );
  }
}