import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

/*

class WorkshopScreen extends ConsumerStatefulWidget {
  final int instanceId; // El ID de la instancia (ej: 3)
  final int courseId;
  final int cmid; // El ID del módulo para la web
  final String title;

  const WorkshopScreen({
    super.key,
    required this.instanceId,
    required this.courseId,
    required this.cmid,
    required this.title,
  });

  @override
  ConsumerState<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends ConsumerState<WorkshopScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _workshopData;
  String? _errorMessage; // Si hay error, guardamos el mensaje aquí
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _cargarTaller();
  }

  // --- 1. CARGAR DATOS (CON PROTECCIÓN ANTI-CONGELAMIENTO) ---
  Future<void> _cargarTaller() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    print("--- DEBUG TALLER ---");
    print("Buscando Taller ID (instance): ${widget.instanceId} en curso: ${widget.courseId}");

    try {
      // Usamos .timeout para que no se quede cargando infinito
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_workshop_get_workshops_by_courses',
          'moodlewsrestformat': 'json',
          'courseids[0]': widget.courseId.toString(),
        },
      ).timeout(const Duration(seconds: 10)); // 10 SEGUNDOS MÁXIMO

      print("Respuesta API: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verificamos si Moodle devolvió error
        if (data is Map && data.containsKey('exception')) {
          throw Exception(data['message']);
        }

        if (data is Map && data.containsKey('workshops')) {
          final List workshops = data['workshops'];
          // Buscamos nuestro taller en la lista
          final myWorkshop = workshops.firstWhere(
            (w) => w['id'] == widget.instanceId,
            orElse: () => null,
          );

          if (myWorkshop != null) {
            if (mounted) {
              setState(() {
                _workshopData = myWorkshop;
                _isLoading = false;
              });
            }
          } else {
             throw Exception("Taller no encontrado en la lista del curso");
          }
        } else {
           throw Exception("Formato de respuesta inesperado");
        }
      } else {
        throw Exception("Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      print("ERROR TALLER: $e");
      // Si falla, NO CRASHEAMOS. Mostramos la pantalla básica.
      if (mounted) {
        setState(() {
          _errorMessage = "No se pudo cargar el detalle (Error: $e).";
          _isLoading = false; // Importante: dejar de cargar
        });
      }
    }
  }

  // --- 2. ABRIR EN WEB ---
  Future<void> _abrirTallerWeb() async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    final url = '$baseUrl/mod/workshop/view.php?id=${widget.cmid}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // --- 3. HELPER FASES ---
  String _getPhaseName(int? phase) {
    switch (phase) {
      case 10: return "Fase de Configuración";
      case 20: return "Fase de Envíos";
      case 30: return "Fase de Evaluación";
      case 40: return "Fase de Calificación";
      case 50: return "Cerrado";
      default: return "Fase Desconocida";
    }
  }

  Color _getPhaseColor(int? phase) {
    if (phase == 20) return Colors.green;
    if (phase == 30) return Colors.orange;
    return Colors.grey;
  }

  // --- 4. FUNCIONES DE HTML/DESCARGA (Copiadas para robustez) ---
  // (Mantengo estas funciones resumidas porque ya las tienes en los otros archivos)
  void _onLinkTapped(String? url) { 
     if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); 
  }

  Widget _buildExternalContentButton(String? url, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
      child: Column(children: [
          Icon(icon, color: Colors.orange.shade800),
          Text(label, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
          ElevatedButton(onPressed: () => url != null ? launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) : _abrirTallerWeb(), child: const Text("Abrir"))
      ]),
    );
  }

// ... (Todo el código anterior de _cargarTaller y demás se mantiene igual) ...

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);
    final isDownloading = _downloadProgress.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taller'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: isDownloading 
            ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo))
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. CABECERA
                  const Icon(Icons.people_alt_rounded, size: 60, color: Colors.indigo),
                  const SizedBox(height: 10),
                  Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 20),

                  // 2. CONTENIDO SI CARGÓ
                  if (_workshopData != null) ...[
                    
                    // A. FASE ACTUAL
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPhaseColor(_workshopData!['phase']).withOpacity(0.1),
                        border: Border.all(color: _getPhaseColor(_workshopData!['phase'])),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: _getPhaseColor(_workshopData!['phase'])),
                          const SizedBox(width: 10),
                          Text("Fase: ${_getPhaseName(_workshopData!['phase'])}", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: _getPhaseColor(_workshopData!['phase']))
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // B. DESCRIPCIÓN GENERAL (Intro)
                    if (_workshopData!['intro'] != null && _workshopData!['intro'] != "")
                      _buildHtmlSection("Descripción", _workshopData!['intro'], token, Icons.description),

                    // C. INSTRUCCIONES PARA EL ENVÍO (instructauthors)
                    // Útil en Fase de Configuración y Envío
                    if (_workshopData!['instructauthors'] != null && _workshopData!['instructauthors'] != "")
                      _buildHtmlSection("Instrucciones para el Envío", _workshopData!['instructauthors'], token, Icons.upload_file),

                    // D. INSTRUCCIONES PARA LA EVALUACIÓN (instructreviewers)
                    // Útil en Fase de Evaluación
                    if (_workshopData!['instructreviewers'] != null && _workshopData!['instructreviewers'] != "")
                      _buildHtmlSection("Instrucciones para Evaluar", _workshopData!['instructreviewers'], token, Icons.rate_review),

                    // E. CONCLUSIÓN (Solo si hay texto)
                    if (_workshopData!['conclusion'] != null && _workshopData!['conclusion'] != "")
                       _buildHtmlSection("Conclusión del Taller", _workshopData!['conclusion'], token, Icons.flag),

                  ] else if (_errorMessage != null) ...[
                    // ERROR
                    Container(
                      padding: const EdgeInsets.all(15),
                      color: Colors.orange.shade50,
                      child: Text(_errorMessage!, textAlign: TextAlign.center),
                    )
                  ],

                  const SizedBox(height: 30),

                  // 3. BOTÓN DE ACCIÓN
                  const Text("Para realizar envíos o evaluaciones:", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text("ENTRAR AL TALLER"),
                      onPressed: _abrirTallerWeb,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // --- HELPER PARA CREAR SECCIONES HTML ---
  // Esto evita repetir código y hace que se vea ordenado (Card o ExpansionTile)
  Widget _buildHtmlSection(String title, String htmlContent, String? token, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile( // Usamos ExpansionTile para que no ocupe tanto espacio si es muy largo
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        childrenPadding: const EdgeInsets.all(16),
        initiallyExpanded: true, // Expandido por defecto para que se vea la info
        children: [
          Html(
            data: htmlContent,
            style: {
              "body": Style(fontSize: FontSize(15.0), margin: Margins.zero, padding: HtmlPaddings.zero),
              "p": Style(margin: Margins.only(bottom: 10)),
            },
            onLinkTap: (url, _, __) => _onLinkTapped(url),
            extensions: [
               // Imágenes con Token
               TagExtension(
                tagsToExtend: {"img"},
                builder: (ctx) {
                  String src = ctx.element?.attributes['src'] ?? "";
                  if (src.contains('pluginfile.php')) {
                    src = src.contains('?') ? '$src&token=$token' : '$src?token=$token';
                  }
                  return Image.network(src, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
                },
              ),
              // Videos y otros
              TagExtension(tagsToExtend: {"video", "iframe"}, builder: (_) => _buildExternalContentButton(null, "Contenido Multimedia", Icons.video_library)),
            ],
          ),
        ],
      ),
    );
  }
}*/


class WorkshopScreen extends ConsumerStatefulWidget {
  final int instanceId;
  final int courseId;
  final int cmid;
  final String title;

  const WorkshopScreen({
    super.key,
    required this.instanceId,
    required this.courseId,
    required this.cmid,
    required this.title,
  });

  @override
  ConsumerState<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends ConsumerState<WorkshopScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _workshopData;
  String? _errorMessage;
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _cargarTaller();
  }

  // --- 1. CARGAR DATOS (Con Timeout y Seguridad) ---
  Future<void> _cargarTaller() async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_workshop_get_workshops_by_courses',
          'moodlewsrestformat': 'json',
          'courseids[0]': widget.courseId.toString(),
        },
      ).timeout(const Duration(seconds: 10)); // Timeout de 10s para no congelar

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data.containsKey('workshops')) {
          final List workshops = data['workshops'];
          final myWorkshop = workshops.firstWhere(
            (w) => w['id'] == widget.instanceId,
            orElse: () => null,
          );

          if (myWorkshop != null) {
            if (mounted) setState(() { _workshopData = myWorkshop; _isLoading = false; });
          } else {
             if (mounted) setState(() { _errorMessage = "Taller no encontrado."; _isLoading = false; });
          }
        } else {
           if (mounted) setState(() { _errorMessage = "No se pudo cargar la información."; _isLoading = false; });
        }
      } else {
        if (mounted) setState(() { _errorMessage = "Error del servidor."; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Error de conexión: $e"; _isLoading = false; });
    }
  }

  // --- 2. ABRIR EN WEB ---
  Future<void> _abrirTallerWeb() async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    final url = '$baseUrl/mod/workshop/view.php?id=${widget.cmid}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // --- 3. FUNCIONES DE DESCARGA Y ARCHIVOS (ROBUSTAS) ---
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
    // Detectar archivos
    if (url.contains('pluginfile.php') || url.endsWith('.pdf') || url.endsWith('.docx') || url.endsWith('.zip') || url.endsWith('.rar')) {
      String filename = "archivo_taller";
      try { filename = url.split('/').last.split('?').first; } catch (_) {}
      _startDownload(url, filename);
    } else {
      // Enlaces externos
      final uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.platformDefault);
        else await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir el enlace")));
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

  // --- 4. BOTÓN DE CONTENIDO EXTERNO (FALLBACK) ---
  Widget _buildExternalContentButton(String? url, String label, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
      child: Column(children: [
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
                 _abrirTallerWeb();
              }
            },
          )
      ]),
    );
  }

  // --- HELPER PARA FASES ---
  String _getPhaseName(int? phase) {
    switch (phase) {
      case 10: return "Fase de Configuración";
      case 20: return "Fase de Envíos";
      case 30: return "Fase de Evaluación";
      case 40: return "Fase de Calificación";
      case 50: return "Cerrado";
      default: return "Estado Desconocido";
    }
  }
  Color _getPhaseColor(int? phase) {
    if (phase == 20) return Colors.green; 
    if (phase == 30) return Colors.orange;
    return Colors.grey;
  }

  // --- 5. RENDERIZADOR HTML REUTILIZABLE ---
  // Esta función aplica TODAS las extensiones (Video, Img, Tabla, etc.) a cualquier texto
  Widget _buildHtmlSection(String title, String htmlContent, IconData icon) {
    final token = ref.read(authTokenProvider); // Leer token actual

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Html(
            data: htmlContent,
            style: {
              "body": Style(fontSize: FontSize(15.0), lineHeight: LineHeight.number(1.5)),
              "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
              "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
              "video": Style(height: Height(200), width: Width(100, Unit.percent)),
            },
            onLinkTap: (url, _, __) => _onLinkTapped(url),
            extensions: [
               // 1. VIDEO
               TagExtension(
                tagsToExtend: {"video"},
                builder: (ctx) {
                  final el = ctx.element;
                  String src = el?.attributes['src'] ?? "";
                  if (src.isEmpty) { for (var c in el!.children) { if (c.localName == 'source') src = c.attributes['src'] ?? ""; } }
                  if (src.isNotEmpty && YoutubePlayer.convertUrlToId(src) != null) return EmbeddedYoutubePlayer(url: src);
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
              // 3. IMÁGENES (CON FALLBACK Y TOKEN)
              TagExtension(
                tagsToExtend: {"img"},
                builder: (ctx) {
                  String src = ctx.element?.attributes['src'] ?? "";
                  if (src.contains('pluginfile.php') && !src.contains('token=')) {
                    src = src.contains('?') ? '$src&token=$token' : '$src?token=$token';
                  }
                  final imageUrl = src;
                  return Image.network(
                    imageUrl, width: double.infinity, fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, p) => p==null ? child : Container(height:150, color:Colors.grey[200], child:const Center(child:CircularProgressIndicator())),
                    errorBuilder: (ctx, e, s) => Container(
                      padding: const EdgeInsets.all(10), margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(border: Border.all(color:Colors.grey.shade300), borderRadius:BorderRadius.circular(8), color:Colors.grey.shade50),
                      child: Column(children: [
                          const Icon(Icons.image_not_supported_outlined, color:Colors.grey),
                          const SizedBox(height: 5),
                          const Text("No se pudo cargar la imagen", style:TextStyle(fontSize:12, color:Colors.grey)),
                          TextButton.icon(icon:const Icon(Icons.open_in_browser, size:14), label:const Text("Abrir"), onPressed:()=>launchUrl(Uri.parse(imageUrl), mode:LaunchMode.externalApplication))
                      ]),
                    ),
                  );
                },
              ),
              // 4. OTROS ELEMENTOS
              TagExtension(tagsToExtend: {"table"}, builder: (_) => _buildExternalContentButton(null, "Ver Tabla", Icons.table_chart)),
              TagExtension(tagsToExtend: {"audio"}, builder: (_) => _buildExternalContentButton(null, "Audio", Icons.audiotrack)),
              TagExtension(tagsToExtend: {"math", "object", "embed"}, builder: (_) => _buildExternalContentButton(null, "Multimedia", Icons.extension)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDownloading = _downloadProgress.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taller'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: isDownloading 
            ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo))
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
                  const Icon(Icons.people_alt_rounded, size: 60, color: Colors.indigo),
                  const SizedBox(height: 10),
                  Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 20),

                  if (_workshopData != null) ...[
                    // FASE ACTUAL
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPhaseColor(_workshopData!['phase']).withOpacity(0.1),
                        border: Border.all(color: _getPhaseColor(_workshopData!['phase'])),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: _getPhaseColor(_workshopData!['phase'])),
                          const SizedBox(width: 10),
                          Text("Fase: ${_getPhaseName(_workshopData!['phase'])}", style: TextStyle(fontWeight: FontWeight.bold, color: _getPhaseColor(_workshopData!['phase']))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECCIONES HTML (Usando el renderizador potente)
                    
                    // 1. Descripción General
                    if (_workshopData!['intro'] != null && _workshopData!['intro'] != "")
                      _buildHtmlSection("Descripción", _workshopData!['intro'], Icons.description),

                    // 2. Instrucciones para Envío
                    if (_workshopData!['instructauthors'] != null && _workshopData!['instructauthors'] != "")
                      _buildHtmlSection("Instrucciones para Enviar", _workshopData!['instructauthors'], Icons.upload_file),

                    // 3. Instrucciones para Evaluar
                    if (_workshopData!['instructreviewers'] != null && _workshopData!['instructreviewers'] != "")
                      _buildHtmlSection("Instrucciones para Evaluar", _workshopData!['instructreviewers'], Icons.rate_review),

                    // 4. Conclusión
                    if (_workshopData!['conclusion'] != null && _workshopData!['conclusion'] != "")
                      _buildHtmlSection("Conclusión", _workshopData!['conclusion'], Icons.flag),

                  ] else if (_errorMessage != null) ...[
                    // ERROR
                    Container(padding: const EdgeInsets.all(15), color: Colors.orange.shade50, child: Text(_errorMessage!, textAlign: TextAlign.center)),
                  ],

                  const SizedBox(height: 30),

                  // BOTÓN DE ACCIÓN
                  const Text("Para realizar envíos o evaluaciones:", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text("ENTRAR AL TALLER"),
                      onPressed: _abrirTallerWeb,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

// VIDEO WIDGET (Imprescindible para que funcione el video)
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