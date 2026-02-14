import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';


// Asegúrate de tener la clase EmbeddedYoutubePlayer en este archivo o importada
// (La incluyo al final por si acaso)

class DescriptionScreen extends ConsumerStatefulWidget {
  final String description;
  final String title; // Opcional: para mostrar un título en el AppBar

  const DescriptionScreen({
    super.key,
    required this.description,
    this.title = 'Introducción',
  });

  @override
  ConsumerState<DescriptionScreen> createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends ConsumerState<DescriptionScreen> {
  final Map<String, double> _downloadProgress = {};

  // --- LÓGICA DE PERMISOS ---
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.manageExternalStorage.request().isGranted) return true;
      if (await Permission.photos.request().isGranted) return true; 
    }
    return await Permission.storage.isGranted;
  }

  // --- DIRECTORIO DE DESCARGAS ---
  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid) return Directory('/storage/emulated/0/Download');
    return await getApplicationDocumentsDirectory();
  }

  // --- GESTIONAR CLICS EN ENLACES ---
  void _onLinkTapped(String? url) async {
    if (url == null) return;

    // A) ARCHIVOS DE MOODLE O DESCARGAS
    if (url.contains('pluginfile.php') || 
        url.endsWith('.pdf') || 
        url.endsWith('.docx') || 
        url.endsWith('.zip') ||
        url.endsWith('.rar')) {
      
      String filename = "archivo";
      try { filename = url.split('/').last.split('?').first; } catch (_) {}
      if (filename.isEmpty) filename = "documento.pdf";
      
      _startDownload(url, filename);
    
    } else {
      // B) ENLACES EXTERNOS
      final uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
           await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
      }
    }
  }

  // --- DESCARGA ---
  Future<void> _startDownload(String fileUrl, String filename) async {
    final granted = await _requestStoragePermission();
    if (granted) await _downloadFile(fileUrl, filename);
    else await _downloadFile(fileUrl, filename); // Fallback intento
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

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Iniciando descarga: $filename...')));

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
      print("Error descarga: $e");
      if (mounted) {
        setState(() { _downloadProgress.remove(fileUrl); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error en la descarga'), backgroundColor: Colors.red));
      }
    }
  }

  // --- BOTÓN DE CONTENIDO EXTERNO ---
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este contenido no tiene un enlace directo disponible.')));
              }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Html(
          data: widget.description, // Aquí usamos el string que recibimos
          
          style: {
            "body": Style(fontSize: FontSize(16.0), lineHeight: LineHeight.number(1.5)),
            "p": Style(padding: HtmlPaddings.zero, margin: Margins.zero),
            "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
            "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
            "video": Style(height: Height(200), width: Width(100, Unit.percent)),
          },
          
          onLinkTap: (url, attributes, element) => _onLinkTapped(url),

          extensions: [
            // 1. VIDEO
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
                return _buildExternalContentButton(src, "Video Web", Icons.videocam_off);
              },
            ),

            // 2. IFRAME (YouTube + H5P)
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

            // 3. IMÁGENES (Token)
           /* TagExtension(
              tagsToExtend: {"img"},
              builder: (extensionContext) {
                final element = extensionContext.element;
                String src = element?.attributes['src'] ?? "";
                if (src.contains('pluginfile.php') && !src.contains('token=')) {
                  src = src.contains('?') ? '$src&token=$token' : '$src?token=$token';
                }

                print("INTENTANDO CARGAR IMAGEN: $src");

                return Image.network(
                  src,
                  errorBuilder: (ctx, error, stack) {
                      print("ERROR CARGANDO IMAGEN $src: $error");
                      return const Icon(Icons.broken_image, color: Colors.grey);
                  },
                );
              },
            ),*/

            TagExtension(
              tagsToExtend: {"img"},
              builder: (extensionContext) {
                final element = extensionContext.element;
                String src = element?.attributes['src'] ?? "";

                // 1. Inyectar Token si es de Moodle
                if (src.contains('pluginfile.php') && !src.contains('token=')) {
                  src = src.contains('?') ? '$src&token=$token' : '$src?token=$token';
                }
                
                final imageUrl = src; // Copia para usar en el botón

                return Image.network(
                  imageUrl,
                  // Ajuste visual
                  width: double.infinity,
                  fit: BoxFit.contain,
                  
                  // Loader mientras carga
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },

                  // MANEJO DE ERROR (Aquí está la magia)
                  errorBuilder: (context, error, stackTrace) {
                    print("Error cargando imagen ($imageUrl): $error");
                    
                    // En vez de un icono roto, mostramos un botón útil
                    return Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                          const SizedBox(height: 5),
                          const Text("No se pudo previsualizar la imagen", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 5),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text("Abrir Imagen"),
                            onPressed: () async {
                              // Usamos externalApplication para que el navegador maneje cookies/sesión si es necesario
                              await launchUrl(Uri.parse(imageUrl), mode: LaunchMode.externalApplication);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // 4. TABLAS
            TagExtension(
              tagsToExtend: {"table"},
              builder: (_) => _buildExternalContentButton(null, "Ver Tabla en Web", Icons.table_chart),
            ),

            // 5. AUDIO
            TagExtension(
              tagsToExtend: {"audio"},
              builder: (_) => _buildExternalContentButton(null, "Audio / Grabación", Icons.audiotrack),
            ),
             
             // 6. OBJETOS
            TagExtension(
              tagsToExtend: {"object", "embed", "math"},
              builder: (_) => _buildExternalContentButton(null, "Contenido Multimedia", Icons.extension),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DE VIDEO (Mantenlo en el mismo archivo o impórtalo) ---
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
















/*
class DescriptionScreen extends StatelessWidget {
  final String description;
  const DescriptionScreen({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Introducción del Curso '),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Html(
          data: description, 
          style: {
            "body": Style(
              fontSize: FontSize(16.0),
              lineHeight: LineHeight.number(1.5),
            ),
            "p": Style( 
               padding: HtmlPaddings.zero,
               margin: Margins.zero,
            ),
          },
        ),
      ),
    );
  }
}*/