import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PageScreen extends ConsumerStatefulWidget {
  final int pageInstanceId;
  final int courseId;
  final String title;

  const PageScreen({
    super.key,
    required this.pageInstanceId,
    required this.courseId,
    required this.title,
  });

  @override
  ConsumerState<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends ConsumerState<PageScreen> {
  bool _isLoading = true;
  String _htmlContent = "";
  final Map<String, double> _downloadProgress = {};

  int? _cmid; 

  @override
  void initState() {
    super.initState();
    _cargarContenidoPagina();
  }

  Future<void> _cargarContenidoPagina() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_page_get_pages_by_courses',
          'moodlewsrestformat': 'json',
          'courseids[0]': widget.courseId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('pages')) {
          final List pages = data['pages'];
          final myPage = pages.firstWhere(
            (p) => p['id'] == widget.pageInstanceId,
            orElse: () => null,
          );

          if (myPage != null) {
            String intro = myPage['intro'] ?? "";
            String body = myPage['content'] ?? "";
            String fullHtml = "$intro<br>$body";
            
            setState(() {
              _htmlContent = fullHtml.isEmpty ? "<p>Sin contenido.</p>" : fullHtml;
              _cmid = myPage['coursemodule']; // Guardamos el ID para abrir la web
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error cargando página: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NUEVA FUNCIÓN: ABRIR TODA LA PÁGINA EN EL NAVEGADOR ---
  Future<void> _abrirPaginaWeb() async {
    if (_cmid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se puede generar el enlace web')));
      return;
    }

    final apiUrl = ref.read(moodleApiUrlProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    
    // URL estándar para ver una Page en Moodle
    final url = '$baseUrl/mod/page/view.php?id=$_cmid';
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir: $e')));
    }
  }

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
        String filename = "archivo";
        try { filename = url.split('/').last.split('?').first; } catch (_) {}
        _startDownload(url, filename);
      } else {
        final uri = Uri.parse(url);
        try {
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
        }
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
  // ... FIN DE FUNCIONES DE DESCARGA ...

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);
    final isDownloading = _downloadProgress.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // 1. BOTÓN DE EMERGENCIA EN EL APPBAR
          // Si algo falla visualmente, el usuario siempre puede tocar aquí
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Abrir en navegador',
            onPressed: _abrirPaginaWeb,
          ),
        ],
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
              padding: const EdgeInsets.all(16.0),
              child: Html(
                data: _htmlContent,
                style: {
                  "body": Style(fontSize: FontSize(16.0), lineHeight: LineHeight.number(1.5)),
                  "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
                  "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
                  "video": Style(height: Height(200), width: Width(100, Unit.percent)),
                },
                onLinkTap: (url, attributes, element) => _onLinkTapped(url),
                extensions: [
                  // EXTENSION VIDEO (Tu código corregido)
                 TagExtension(
                    tagsToExtend: {"table"},
                    builder: (extensionContext) {
                      // En lugar de intentar renderizar la tabla, mostramos el botón
                      return _buildExternalContentButton(
                        null, // Null para que abra la página completa
                        "Tabla de Datos Compleja",
                        Icons.table_chart_rounded
                      );
                    },
                  ),

                  // --- 2. NUEVO: MANEJO DE AUDIO ---
                  TagExtension(
                    tagsToExtend: {"audio"},
                    builder: (extensionContext) {
                       // Intentamos obtener la fuente del audio por si acaso
                       final element = extensionContext.element;
                       String src = element?.attributes['src'] ?? "";
                       if (src.isEmpty && element != null) {
                        for (var child in element.children) {
                          if (child.localName == 'source') src = child.attributes['src'] ?? "";
                        }
                      }
                      
                      return _buildExternalContentButton(
                        src.isNotEmpty ? src : null, 
                        "Audio / Grabación",
                        Icons.audiotrack_rounded
                      );
                    },
                  ),

                  // --- 3. VIDEO (Tu lógica existente + el nuevo botón) ---
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
                      // Si es YouTube, lo mostramos nativo
                      if (src.isNotEmpty && YoutubePlayer.convertUrlToId(src) != null) {
                        return EmbeddedYoutubePlayer(url: src);
                      }
                      // Si no, mandamos a la web
                      return _buildExternalContentButton(src, "Video Formato Web", Icons.videocam_off);
                    },
                  ),

                  // --- 4. IFRAME (Tu lógica existente + el nuevo botón) ---
                  TagExtension(
                    tagsToExtend: {"iframe"},
                    builder: (extensionContext) {
                      final element = extensionContext.element;
                      String src = element?.attributes['src'] ?? "";
                      if (src.startsWith('//')) src = 'https:$src';

                      if (YoutubePlayer.convertUrlToId(src) != null) {
                        return EmbeddedYoutubePlayer(url: src);
                      }
                      
                      // Para H5P, Genially, etc.
                      return _buildExternalContentButton(src, "Contenido Interactivo", Icons.touch_app);
                    },
                  ),
                 
                  // Moodle suele usar la etiqueta <math> o spans con clases complejas.
                  TagExtension(
                    tagsToExtend: {"math"},
                    builder: (extensionContext) {
                      return _buildExternalContentButton(
                        null, 
                        "Ecuación Matemática", 
                        Icons.functions_rounded
                      );
                    },
                  ),

                  // --- 6. FECHAS Y HORAS DINÁMICAS ---
                  TagExtension(
                    tagsToExtend: {"time"},
                    builder: (extensionContext) {
                      // Obtenemos el texto de la fecha si es posible
                      final dateText = extensionContext.element?.text ?? "Fecha";
                      return _buildExternalContentButton(
                        null, 
                        "Dato de Tiempo: $dateText", 
                        Icons.access_time_filled_rounded
                      );
                    },
                  ),

                  // --- 7. OBJETOS EMBEBIDOS GENÉRICOS (PDFs, Flash, Applets) ---
                  TagExtension(
                    tagsToExtend: {"object", "embed"},
                    builder: (extensionContext) {
                      final element = extensionContext.element;
                      String src = element?.attributes['src'] ?? element?.attributes['data'] ?? "";
                      
                      return _buildExternalContentButton(
                        src.isNotEmpty ? src : null, 
                        "Objeto Multimedia", 
                        Icons.extension_rounded
                      );
                    },
                  ),

                  // --- 8. FORMULARIOS (Botones, Inputs, Encuestas dentro de la página) ---
                  TagExtension(
                    tagsToExtend: {"form", "input", "button"},
                    builder: (extensionContext) {
                      return _buildExternalContentButton(
                        null, 
                        "Elemento Interactivo / Formulario", 
                        Icons.touch_app_rounded
                      );
                    },
                  ),

                  TagExtension(
                    tagsToExtend: {"img"},
                    builder: (extensionContext) {
                      final element = extensionContext.element;
                      String src = element?.attributes['src'] ?? "";
                      if (src.contains('pluginfile.php') && !src.contains('token=')) {
                        src = src.contains('?') ? '$src&token=$token' : '$src?token=$token';
                      }
                      return Image.network(
                        src,
                        errorBuilder: (ctx, error, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildExternalContentButton(String? url, String label, IconData icon) {
    return Container(
      width: double.infinity, // Ocupar todo el ancho
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50, // Un color suave diferente
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange.shade800, size: 30),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          const Text(
            "Visualización web recomendada",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text("Ver en Navegador"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (url != null && url.isNotEmpty) {
                // Si hay una URL específica (ej: el src de un iframe), abrimos esa
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } else {
                // Si es una tabla o contenido incrustado, abrimos LA PÁGINA COMPLETA DE MOODLE
                _abrirPaginaWeb(); 
              }
            },
          )
        ],
      ),
    );
  }
}

// (Tu clase EmbeddedYoutubePlayer sigue aquí abajo igual que antes)
class EmbeddedYoutubePlayer extends StatefulWidget {
  final String url;
  const EmbeddedYoutubePlayer({super.key, required this.url});
  @override
  State<EmbeddedYoutubePlayer> createState() => _EmbeddedYoutubePlayerState();
}
// ... (El resto del código de EmbeddedYoutubePlayer) ...
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