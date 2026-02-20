import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/*
class ForumDiscussionScreen extends ConsumerStatefulWidget {
  final int discussionId;
  final String subject;

  const ForumDiscussionScreen({
    super.key,
    required this.discussionId,
    required this.subject,
  });

  @override
  ConsumerState<ForumDiscussionScreen> createState() => _ForumDiscussionScreenState();
}

class _ForumDiscussionScreenState extends ConsumerState<ForumDiscussionScreen> {
  bool _isLoading = true;
  List<dynamic> _posts = [];
  String? _errorMessage;

  // Controladores para la respuesta
  final _replyMessageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _cargarPosts();
  }

  @override
  void dispose() {
    _replyMessageController.dispose();
    super.dispose();
  }

  // --- 1. CARGAR POSTS ---
  Future<void> _cargarPosts() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_forum_get_discussion_posts',
          'moodlewsrestformat': 'json',
          'discussionid': widget.discussionId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('exception')) {
          if (mounted) setState(() { _errorMessage = data['message']; _isLoading = false; });
          return;
        }

        List postsList = [];
        if (data is Map && data.containsKey('posts')) {
          postsList = data['posts'];
        } else if (data is List) {
          postsList = data;
        }

        if (mounted) setState(() { _posts = postsList; _isLoading = false; });
      } else {
        if (mounted) setState(() { _errorMessage = "Error servidor: ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Error conexión: $e"; _isLoading = false; });
    }
  }

  // --- 2. ENVIAR RESPUESTA ---
  Future<void> _enviarRespuesta(int parentPostId, String parentSubject) async {
    if (_replyMessageController.text.isEmpty) return;

    setState(() => _isSending = true);
    Navigator.pop(context); // Cierra el diálogo

    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);
    
    // Moodle suele requerir que el asunto empiece con "Re:"
    String replySubject = parentSubject.startsWith("Re:") ? parentSubject : "Re: $parentSubject";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_forum_add_discussion_post', // <--- FUNCIÓN REQUERIDA
          'moodlewsrestformat': 'json',
          'postid': parentPostId.toString(), // A quién respondemos
          'subject': replySubject,
          'message': _replyMessageController.text,
        },
      );

      final data = json.decode(response.body);

      if (data is Map && data.containsKey('postid')) {
        // ÉXITO
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Respuesta enviada"), backgroundColor: Colors.green));
        _replyMessageController.clear();
        _cargarPosts(); // Recargar para ver la respuesta
      } else {
        String msg = data['message'] ?? "Error desconocido";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $msg"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error conexión: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // --- 3. MOSTRAR DIÁLOGO ---
  void _mostrarDialogoRespuesta(int parentId, String parentSubject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Responder"),
        content: TextField(
          controller: _replyMessageController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Escribe tu respuesta aquí...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _enviarRespuesta(parentId, parentSubject),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE DATOS ---
  String _getAuthorName(Map<String, dynamic> post) {
    if (post['author'] != null && post['author'] is Map) {
      return post['author']['fullname'] ?? 'Usuario';
    }
    return post['userfullname'] ?? 'Usuario';
  }

  String? _getAuthorImage(Map<String, dynamic> post) {
    if (post['author'] != null && post['author'] is Map) {
      final author = post['author'];
      if (author['urls'] != null && author['urls']['profileimage'] != null) {
        return author['urls']['profileimage'];
      }
    }
    return post['userpictureurl'];
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM HH:mm').format(date);
  }

  void _onLinkTapped(String? url) {
    if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: _isSending ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo)) : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _posts.isEmpty
                  ? const Center(child: Text("No hay mensajes."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final isParent = (post['parent'] == 0); 
                        final authorName = _getAuthorName(post);
                        final authorImage = _getAuthorImage(post);
                        final postId = post['id']; // ID para responder
                        final postSubject = post['subject'] ?? widget.subject;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isParent ? const BorderSide(color: Colors.indigo, width: 2) : BorderSide.none,
                          ),
                          elevation: isParent ? 4 : 2,
                          color: isParent ? Colors.indigo.shade50 : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CABECERA
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.indigo.shade100,
                                      backgroundImage: (authorImage != null) ? NetworkImage(authorImage) : null,
                                      child: (authorImage == null) ? const Icon(Icons.person, color: Colors.indigo) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Text(_formatDate(post['created']), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                
                                // CONTENIDO
                                Html(
                                  data: post['message'] ?? "",
                                  style: {"body": Style(fontSize: FontSize(15.0), margin: Margins.zero)},
                                  onLinkTap: (url, _, __) => _onLinkTapped(url),
                                  extensions: [
                                    TagExtension(
                                      tagsToExtend: {"img"},
                                      builder: (ctx) {
                                        String src = ctx.element?.attributes['src'] ?? "";
                                        if (src.contains('pluginfile.php')) { src = src.contains('?') ? '$src&token=$token' : '$src?token=$token'; }
                                        return Image.network(src, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // BOTÓN DE RESPONDER
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.reply, size: 18),
                                    label: const Text("Responder"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.indigo,
                                    ),
                                    onPressed: () => _mostrarDialogoRespuesta(postId, postSubject),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}*/

class ForumDiscussionScreen extends ConsumerStatefulWidget {
  final int discussionId;
  final String subject;

  const ForumDiscussionScreen({
    super.key,
    required this.discussionId,
    required this.subject,
  });

  @override
  ConsumerState<ForumDiscussionScreen> createState() =>
      _ForumDiscussionScreenState();
}

class _ForumDiscussionScreenState
    extends ConsumerState<ForumDiscussionScreen> {

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadDiscussionPosts();
  }

  // ✅ ESTA ES LA PARTE IMPORTANTE
  Future<void> _loadDiscussionPosts() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_forum_get_discussion_posts',
          'moodlewsrestformat': 'json',
          'discussionid': widget.discussionId.toString(),
        },
      );

      final data = json.decode(response.body);

      if (data is Map && data.containsKey('posts')) {
        setState(() {
          _posts = data['posts'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "No se pudieron cargar los mensajes";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error de conexión";
        _isLoading = false;
      });
    }
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return "";
    final date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];

                    final message = post['message'] ?? "";
                    final author =
                        post['userfullname'] ?? "Anónimo";
                    final date =
                        _formatDate(post['created']);
                    final depth =
                        post['parent'] == 0 ? 0 : 1;

                    return Padding(
                      padding: EdgeInsets.only(
                          left: depth == 1 ? 25 : 0,
                          bottom: 15),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        Colors.indigo,
                                    child: Icon(
                                      Icons.person,
                                      size: 14,
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 8),
                                  Expanded(
                                    child: Text(
                                      author,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                  height: 10),

                              // ✅ AQUÍ SE MUESTRA EL CONTENIDO REAL
                              Html(
                                data: message,
                                extensions: [
                                  TagExtension(
                                    tagsToExtend: {
                                      "img"
                                    },
                                    builder: (ctx) {
                                      String src =
                                          ctx.element
                                                  ?.attributes[
                                              'src'] ??
                                              "";
                                      if (src.contains(
                                          'pluginfile.php')) {
                                        src = src
                                                .contains(
                                                    '?')
                                            ? '$src&token=$token'
                                            : '$src?token=$token';
                                      }
                                      return Image
                                          .network(
                                              src);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}