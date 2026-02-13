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
  
  // Variable para controlar el progreso de descarga (URL -> Porcentaje)
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _cargarContenidoPagina();
  }

  // --- 1. LÓGICA DE CARGA DE MOODLE (Igual que antes) ---
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
            setState(() {
              _htmlContent = myPage['content'] ?? "<p>Sin contenido.</p>";
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

  // --- 2. LÓGICA DE PERMISOS (Copiada de tu ejemplo) ---
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.manageExternalStorage.request().isGranted) return true;
      if (await Permission.photos.request().isGranted) return true; 
    }
    return await Permission.storage.isGranted;
  }

  // --- 3. DIRECTORIO DE DESCARGAS ---
  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    return await getApplicationDocumentsDirectory();
  }

  // --- 4. DETECTAR Y GESTIONAR CLICS EN ENLACES ---
  void _onLinkTapped(String? url) async {
    if (url == null) return;

    // A) Si es un archivo interno de Moodle (pluginfile) -> DESCARGAR
    // También detectamos extensiones comunes por si acaso
    if (url.contains('pluginfile.php') || 
        url.endsWith('.pdf') || 
        url.endsWith('.docx') || 
        url.endsWith('.zip')) {
      
      // Extraemos un nombre de archivo del URL o usamos uno genérico
      String filename = "archivo_descargado";
      try {
        // Intento básico de sacar el nombre de la URL
        filename = url.split('/').last.split('?').first; 
      } catch (e) {
        filename = "documento_moodle.pdf";
      }

      _startDownload(url, filename);
    
    } else {
      // B) Si es un enlace externo (Google, Wikipedia, etc.) -> ABRIR NAVEGADOR
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // --- 5. INICIAR DESCARGA ---
  Future<void> _startDownload(String fileUrl, String filename) async {
    final granted = await _requestStoragePermission();
    if (granted) {
      await _downloadFile(fileUrl, filename);
    } else {
      if (mounted) {
        // Intento de fallback por si el permiso es implícito
        await _downloadFile(fileUrl, filename);
      }
    }
  }

  // --- 6. DESCARGA CON DIO (Tu lógica adaptada) ---
  Future<void> _downloadFile(String fileUrl, String filename) async {
    final dir = await getDownloadsDirectory();
    final savePath = '${dir?.path}/$filename';
    final token = ref.read(authTokenProvider);
    
    if (token == null) return;
    
    // Inyectar Token si es URL de Moodle
    String finalUrl = fileUrl;
    if (fileUrl.contains('pluginfile.php')) {
        finalUrl = fileUrl.contains('?') 
          ? '$fileUrl&token=$token' 
          : '$fileUrl?token=$token';
    }

    // Mostrar SnackBar inicial
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Iniciando descarga: $filename...')),
      );
    }

    try {
      await Dio().download(
        finalUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() { 
              // Actualizamos el progreso para mostrar (opcionalmente) una barra
              _downloadProgress[fileUrl] = received / total; 
            });
          }
        },
      );
      
      if (mounted) {
        setState(() { _downloadProgress.remove(fileUrl); }); // Limpiar progreso

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Descarga completa!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ABRIR', 
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(savePath)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error descarga: $e');
      if (mounted) {
        setState(() { _downloadProgress.remove(fileUrl); });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);

    // Verificamos si hay alguna descarga activa para mostrar barra de carga global
    final isDownloading = _downloadProgress.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
              padding: const EdgeInsets.all(16.0),
              child: Html(
                data: _htmlContent,
                
                // ESTILOS
                style: {
                  "body": Style(
                    fontSize: FontSize(16.0),
                    lineHeight: LineHeight.number(1.5),
                  ),
                  "img": Style(
                    width: Width(100, Unit.percent),
                    height: Height.auto(),
                  ),
                  // Hacer que los enlaces se vean como botones o resaltados si quieres
                  "a": Style(
                    textDecoration: TextDecoration.none,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                },

                // AQUI INTERCEPTAMOS LOS CLICS EN ENLACES
                onLinkTap: (url, attributes, element) {
                  _onLinkTapped(url);
                },

                // EXTENSIÓN PARA IMÁGENES (Mantener tu lógica de token)
                extensions: [
                  TagExtension(
                    tagsToExtend: {"img"},
                    builder: (extensionContext) {
                      final element = extensionContext.element;
                      String src = element?.attributes['src'] ?? "";
                      
                      if (src.contains('pluginfile.php') && !src.contains('token=')) {
                        if (src.contains('?')) {
                          src = '$src&token=$token';
                        } else {
                          src = '$src?token=$token';
                        }
                      }
                      return Image.network(
                        src,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                             height: 200, 
                             color: Colors.grey[200],
                             child: const Center(child: CircularProgressIndicator())
                          );
                        },
                        errorBuilder: (ctx, error, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

/*class PageScreen extends ConsumerWidget {
  final int moduleId; // cmid
  final String title;

  const PageScreen({
    super.key,
    required this.moduleId,
    required this.title,
  });

  Future<void> _abrirEnNavegador(BuildContext context, String apiUrl) async {
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    
    // URL estándar de Moodle para Página
    final url = '$baseUrl/mod/page/view.php?id=$moduleId';
    final uri = Uri.parse(url);

    try {
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('No se pudo abrir la página');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiUrl = ref.watch(moodleApiUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurso Página'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de documento web
            const Icon(Icons.article_rounded, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            const Text(
              "Esta página puede contener videos, imágenes protegidas o tablas complejas. Se abrirá en tu navegador para asegurar que veas todo el contenido correctamente.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_browser),
                label: const Text("VER CONTENIDO DE LA PÁGINA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _abrirEnNavegador(context, apiUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/