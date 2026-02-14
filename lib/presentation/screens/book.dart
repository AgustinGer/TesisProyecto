import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';



// --- PANTALLA PRINCIPAL DEL LIBRO ---
class BookScreen extends ConsumerStatefulWidget {
  final int bookId; // ID de la instancia del libro (module['instance'])
  final int cmid;   // ID del módulo del curso (para abrir en web)
  final String title;

  const BookScreen({
    super.key,
    required this.bookId,
    required this.cmid,
    required this.title,
  });

  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  bool _isLoading = true;
  List<dynamic> _chapters = [];
  int _currentIndex = 0; // Índice del capítulo que estamos viendo
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _cargarCapitulos();
  }

  // --- 1. CARGAR CAPÍTULOS DESDE MOODLE ---
  Future<void> _cargarCapitulos() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_book_get_book_contents', // API específica de libros
          'moodlewsrestformat': 'json',
          'bookid': widget.bookId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // La API devuelve una lista directa de capítulos bajo 'items' o directamente la lista
        List items = [];
        if (data is Map && data.containsKey('items')) {
          items = data['items'];
        } else if (data is List) {
          // A veces devuelve error o lista vacía
        }

        if (items.isNotEmpty) {
          setState(() {
            _chapters = items;
            _isLoading = false;
          });
        } else {
           setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("Error cargando libro: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NAVEGACIÓN ENTRE CAPÍTULOS ---
  void _irCapituloSiguiente() {
    if (_currentIndex < _chapters.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _irCapituloAnterior() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _irCapituloEspecifico(int index) {
    setState(() => _currentIndex = index);
    Navigator.pop(context); // Cerrar el Drawer (menú lateral)
  }

  // --- ABRIR EN WEB (BOTÓN MUNDO) ---
  Future<void> _abrirEnWeb() async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    final url = '$baseUrl/mod/book/view.php?id=${widget.cmid}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ... (TUS FUNCIONES DE DESCARGA: _requestStoragePermission, _onLinkTapped, etc.) ...
  // COPIA AQUÍ LAS MISMAS FUNCIONES QUE USASTE EN PAGESCREEN/DESCRIPTIONSCREEN
  // Para no hacer el código gigante, asumo que las tienes (son idénticas).
  // --- INICIO RESUMEN DE FUNCIONES AUXILIARES ---
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
      String filename = "archivo_libro";
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
  // --- FIN RESUMEN FUNCIONES AUXILIARES ---

  // Botón auxiliar para contenido externo
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
          Text(label, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text("Abrir"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              else _abrirEnWeb();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);
    final isDownloading = _downloadProgress.isNotEmpty;
    
    // Obtenemos el contenido del capítulo actual
    String chapterContent = "";
    String chapterTitle = "";
    
    if (_chapters.isNotEmpty) {
      chapterContent = _chapters[_currentIndex]['content'] ?? "";
      chapterTitle = _chapters[_currentIndex]['title'] ?? "";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Título del Libro
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Ver en Web',
            onPressed: _abrirEnWeb,
          ),
        ],
        bottom: isDownloading 
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo),
              )
            : null,
      ),
      
      // --- DRAWER: TABLA DE CONTENIDOS ---
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Tabla de Contenidos"),
              accountEmail: Text(widget.title),
              decoration: const BoxDecoration(color: Colors.indigo),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.menu_book_rounded, color: Colors.indigo, size: 30),
              ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      // Detectar si es subcapítulo (generalmente no tienen nivel en API JSON simple, 
                      // pero si tuvieran, podrías añadir padding)
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _currentIndex == index ? Colors.indigo : Colors.grey[200],
                          child: Text("${index + 1}", 
                            style: TextStyle(color: _currentIndex == index ? Colors.white : Colors.black87)
                          ),
                        ),
                        title: Text(
                          chapter['title'],
                          style: TextStyle(
                            fontWeight: _currentIndex == index ? FontWeight.bold : FontWeight.normal,
                            color: _currentIndex == index ? Colors.indigo : Colors.black87,
                          ),
                        ),
                        selected: _currentIndex == index,
                        onTap: () => _irCapituloEspecifico(index),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),

      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _chapters.isEmpty 
            ? const Center(child: Text("Este libro no tiene capítulos."))
            : Column(
                children: [
                  // --- TÍTULO DEL CAPÍTULO ACTUAL ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey[100],
                    child: Text(
                      chapterTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // --- CONTENIDO HTML ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Html(
                        data: chapterContent,
                        
                        // ESTILOS IGUAL QUE EN PANTALLA PÁGINA
                        style: {
                          "body": Style(fontSize: FontSize(16.0), lineHeight: LineHeight.number(1.5)),
                          "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
                          "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
                          "video": Style(height: Height(200), width: Width(100, Unit.percent)),
                        },
                        
                        onLinkTap: (url, attributes, element) => _onLinkTapped(url),

                        // EXTENSIONES ROBUSTAS (Copiadas de lo que ya hicimos)
                        extensions: [
                          // VIDEO
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
                          // IFRAME
                          TagExtension(
                            tagsToExtend: {"iframe"},
                            builder: (ctx) {
                              String src = ctx.element?.attributes['src'] ?? "";
                              if (src.startsWith('//')) src = 'https:$src';
                              if (YoutubePlayer.convertUrlToId(src) != null) return EmbeddedYoutubePlayer(url: src);
                              return _buildExternalContentButton(src, "Contenido Interactivo", Icons.touch_app);
                            },
                          ),
                          // IMG (CON TOKEN)
                          TagExtension(
                            tagsToExtend: {"img"},
                            builder: (ctx) {
                              String src = ctx.element?.attributes['src'] ?? "";
                              if (src.contains('pluginfile.php') && !src.contains('token=')) {
                                src = src.contains('?') ? '$src&token=$token' : '$src?token=$token';
                              }
                              // Usamos Image.network simple, si quieres el avanzado con botón, copia el de PageScreen
                              return Image.network(src, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)); 
                            },
                          ),
                          // TABLAS, AUDIO, ETC.
                          TagExtension(
                            tagsToExtend: {"table"},
                            builder: (_) => _buildExternalContentButton(null, "Tabla de Datos", Icons.table_chart),
                          ),
                           TagExtension(
                            tagsToExtend: {"audio"},
                            builder: (_) => _buildExternalContentButton(null, "Audio", Icons.audiotrack),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- BOTONES DE NAVEGACIÓN INFERIOR ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BOTÓN ANTERIOR
                        _currentIndex > 0
                            ? ElevatedButton.icon(
                                onPressed: _irCapituloAnterior,
                                icon: const Icon(Icons.arrow_back_ios, size: 16),
                                label: const Text("Anterior"),
                              )
                            : const SizedBox(width: 100), // Espacio vacío para equilibrar

                        // INDICADOR DE PÁGINA
                        Text("${_currentIndex + 1} / ${_chapters.length}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
                        ),

                        // BOTÓN SIGUIENTE
                        _currentIndex < _chapters.length - 1
                            ? ElevatedButton.icon(
                                onPressed: _irCapituloSiguiente,
                                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                label: const Text("Siguiente"),
                                style: ElevatedButton.styleFrom(
                                   // Ponemos el icono a la derecha con direction
                                   iconAlignment: IconAlignment.end
                                ),
                              )
                            : const SizedBox(width: 100),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

// Widget de Youtube (Necesario si no está en otro archivo)
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