import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Importante
import 'package:dio/dio.dart'; // Importante
import 'package:path_provider/path_provider.dart'; // Importante
import 'package:permission_handler/permission_handler.dart'; // Importante
import 'package:open_filex/open_filex.dart'; // Importante



// --- PANTALLA DE EXAMEN ---
class QuizScreen extends ConsumerStatefulWidget {
  final int quizInstanceId;
  final int courseId;
  final int cmid;
  final String title;

  const QuizScreen({
    super.key,
    required this.quizInstanceId,
    required this.courseId,
    required this.cmid,
    required this.title,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _quizData;
  String? _errorMessage;
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _cargarInfoExamen();
  }

  // --- 1. CARGAR DATOS DEL QUIZ ---
  Future<void> _cargarInfoExamen() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_quiz_get_quizzes_by_courses',
          'moodlewsrestformat': 'json',
          'courseids[0]': widget.courseId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('quizzes')) {
          final List quizzes = data['quizzes'];
          final myQuiz = quizzes.firstWhere(
            (q) => q['id'] == widget.quizInstanceId,
            orElse: () => null,
          );

          if (myQuiz != null) {
            setState(() {
              _quizData = myQuiz;
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = "No se encontró información detallada del examen.";
              _isLoading = false;
            });
          }
        } else {
           setState(() {
             _errorMessage = "No se pudo cargar detalles. Intente abrirlo directamente.";
             _isLoading = false;
           });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error de conexión: $e";
        _isLoading = false;
      });
    }
  }

  // --- 2. ABRIR EXAMEN EN WEB ---
  Future<void> _abrirExamenWeb() async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    final url = '$baseUrl/mod/quiz/view.php?id=${widget.cmid}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // --- 3. FUNCIONES DE DESCARGA Y ARCHIVOS (IGUAL QUE EN OTRAS PANTALLAS) ---
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.manageExternalStorage.request().isGranted) return true;
      if (await Permission.photos.request().isGranted) return true; 
    }
    return await Permission.storage.isGranted;
  }
  
  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid) return Directory('/storage/emulated/0/Download');
    return await getApplicationDocumentsDirectory();
  }

  void _onLinkTapped(String? url) async {
    if (url == null) return;
    if (url.contains('pluginfile.php') || url.endsWith('.pdf') || url.endsWith('.docx') || url.endsWith('.zip')) {
      String filename = "archivo_examen";
      try { filename = url.split('/').last.split('?').first; } catch (_) {}
      _startDownload(url, filename);
    } else {
      final uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.platformDefault);
        else await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {}
    }
  }

  Future<void> _startDownload(String fileUrl, String filename) async {
    final granted = await _requestStoragePermission();
    if (granted) await _downloadFile(fileUrl, filename);
    else await _downloadFile(fileUrl, filename);
  }

  Future<void> _downloadFile(String fileUrl, String filename) async {
    final dir = await getDownloadsDirectory();
    final savePath = '${dir?.path}/$filename';
    final token = ref.read(authTokenProvider);
    if (token == null) return;
    String finalUrl = fileUrl;
    if (fileUrl.contains('pluginfile.php')) {
        finalUrl = fileUrl.contains('?') ? '$fileUrl&token=$token' : '$fileUrl?token=$token';
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Descargando: $filename...')));
    try {
      await Dio().download(finalUrl, savePath, onReceiveProgress: (r, t) {
          if (t != -1) setState(() { _downloadProgress[fileUrl] = r / t; });
      });
      if (mounted) {
        setState(() { _downloadProgress.remove(fileUrl); });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Descarga completa!'), backgroundColor: Colors.green,
          action: SnackBarAction(label: 'ABRIR', textColor: Colors.white, onPressed: () => OpenFilex.open(savePath)),
        ));
      }
    } catch (e) {
      if (mounted) setState(() { _downloadProgress.remove(fileUrl); });
    }
  }

  // --- 4. BOTÓN DE CONTENIDO EXTERNO (FALLBACK) ---
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
                _abrirExamenWeb(); // Si falla algo interno, abrimos todo el examen
              }
            },
          )
        ],
      ),
    );
  }

  // Helper para fechas
  String _formatDate(int? timestamp) {
    if (timestamp == null || timestamp == 0) return "Sin fecha";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  // Helper para duración
  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return "Sin límite";
    final duration = Duration(seconds: seconds);
    return "${duration.inMinutes} minutos";
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);
    final isDownloading = _downloadProgress.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examen'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: isDownloading 
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CABECERA
                  const Icon(Icons.quiz_rounded, size: 60, color: Colors.indigo),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 20),

                  if (_quizData != null) ...[
                    // --- AQUÍ APLICAMOS EL HTML ROBUSTO ---
                    if (_quizData!['intro'] != null && _quizData!['intro'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200)
                        ),
                        child: Html(
                          data: _quizData!['intro'],
                          
                          // ESTILOS
                          style: {
                            "body": Style(fontSize: FontSize(16.0), lineHeight: LineHeight.number(1.5)),
                            "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
                            "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
                            "video": Style(height: Height(200), width: Width(100, Unit.percent)),
                          },
                          
                          onLinkTap: (url, attributes, element) => _onLinkTapped(url),

                          // EXTENSIONES COMPLETAS
                          extensions: [
                            // 1. VIDEO
                            TagExtension(
                              tagsToExtend: {"video"},
                              builder: (ctx) {
                                final el = ctx.element;
                                String src = el?.attributes['src'] ?? "";
                                if (src.isEmpty) {
                                  for (var c in el!.children) { if (c.localName == 'source') src = c.attributes['src'] ?? ""; }
                                }
                                if (src.isNotEmpty && YoutubePlayer.convertUrlToId(src) != null) {
                                  return EmbeddedYoutubePlayer(url: src);
                                }
                                return _buildExternalContentButton(src, "Video Web", Icons.videocam_off);
                              },
                            ),
                            // 2. IFRAME
                            TagExtension(
                              tagsToExtend: {"iframe"},
                              builder: (ctx) {
                                String src = ctx.element?.attributes['src'] ?? "";
                                if (src.startsWith('//')) src = 'https:$src';
                                if (YoutubePlayer.convertUrlToId(src) != null) return EmbeddedYoutubePlayer(url: src);
                                return _buildExternalContentButton(src, "Contenido Interactivo", Icons.touch_app);
                              },
                            ),
                            // 3. IMÁGENES (CON FALLBACK)
                            TagExtension(
                              tagsToExtend: {"img"},
                              builder: (extensionContext) {
                                final element = extensionContext.element;
                                String src = element?.attributes['src'] ?? "";
                                if (src.contains('pluginfile.php') && !src.contains('token=')) {
                                  src = src.contains('?') ? '$src&token=$token' : '$src?token=$token';
                                }
                                final imageUrl = src;
                                return Image.network(
                                  imageUrl,
                                  width: double.infinity, fit: BoxFit.contain,
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return Container(height: 150, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                                  },
                                  errorBuilder: (ctx, error, stack) {
                                    return Container(
                                      padding: const EdgeInsets.all(10), margin: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade50),
                                      child: Column(children: [
                                          const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                          const SizedBox(height: 5),
                                          const Text("Error cargando imagen", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          TextButton.icon(icon: const Icon(Icons.open_in_browser, size: 14), label: const Text("Abrir"), onPressed: () async { await launchUrl(Uri.parse(imageUrl), mode: LaunchMode.externalApplication); })
                                      ]),
                                    );
                                  },
                                );
                              },
                            ),
                            // 4. TABLAS, AUDIO, OTROS
                            TagExtension(
                              tagsToExtend: {"table"},
                              builder: (_) => _buildExternalContentButton(null, "Ver Tabla en Web", Icons.table_chart),
                            ),
                            TagExtension(
                              tagsToExtend: {"audio"},
                              builder: (_) => _buildExternalContentButton(null, "Audio", Icons.audiotrack),
                            ),
                             TagExtension(
                              tagsToExtend: {"object", "embed", "math"},
                              builder: (_) => _buildExternalContentButton(null, "Contenido Multimedia", Icons.extension),
                            ),
                          ],
                        ),
                      ),

                    // INFORMACIÓN DEL EXAMEN (Tarjetas)
                    Row(
                      children: [
                        Expanded(child: _InfoCard(icon: Icons.timer, label: "Límite", value: _formatDuration(_quizData!['timelimit']))),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoCard(icon: Icons.repeat, label: "Intentos", value: _quizData!['attempts'] == 0 ? "Ilimitados" : "${_quizData!['attempts']}")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(icon: Icons.calendar_today, label: "Cierra", value: _formatDate(_quizData!['timeclose'])),
                    
                    const SizedBox(height: 40),
                  ] 
                  else if (_errorMessage != null) ...[
                    Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                  ],

                  // BOTÓN DE ACCIÓN PRINCIPAL
                  const Text(
                    "El examen se abrirá en tu navegador para asegurar la estabilidad.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text("IR AL CUESTIONARIO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: _abrirExamenWeb,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- WIDGETS AUXILIARES ---
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Column(children: [
          Icon(icon, color: Colors.indigo, size: 24),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
    );
  }
}

// Widget de Youtube (Necesario si no está importado)
class EmbeddedYoutubePlayer extends StatefulWidget {
  final String url;
  const EmbeddedYoutubePlayer({super.key, required this.url});
  @override
  State<EmbeddedYoutubePlayer> createState() => _EmbeddedYoutubePlayerState();
}
class _EmbeddedYoutubePlayerState extends State<EmbeddedYoutubePlayer> {
  late YoutubePlayerController _c;
  bool _ok = false;
  @override void initState() { super.initState(); var id=YoutubePlayer.convertUrlToId(widget.url); if(id!=null){_ok=true;_c=YoutubePlayerController(initialVideoId:id,flags:const YoutubePlayerFlags(autoPlay:false,mute:false));}}
  @override void dispose() { if(_ok)_c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { if(!_ok)return const SizedBox(); return Container(margin:const EdgeInsets.symmetric(vertical:10), child:YoutubePlayer(controller:_c, bottomActions:[CurrentPosition(),ProgressBar(isExpanded:true),RemainingDuration()])); }
}
