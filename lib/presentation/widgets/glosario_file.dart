import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/glosario_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
// Importa tus providers de autenticación
import 'package:flutter_tesis/provider/auth_provider.dart'; 


class GlossaryFileWidget extends ConsumerStatefulWidget {
  final GlossaryFile file;

  const GlossaryFileWidget({super.key, required this.file});

  @override
  ConsumerState<GlossaryFileWidget> createState() => _GlossaryFileWidgetState();
}

class _GlossaryFileWidgetState extends ConsumerState<GlossaryFileWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;

  // Icono según extensión
  IconData _getIcon(String filename) {
    if (filename.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (filename.endsWith('.jpg') || filename.endsWith('.png')) return Icons.image;
    if (filename.endsWith('.doc') || filename.endsWith('.docx')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Future<void> _downloadAndOpen() async {
    // 1. Permisos (Simplificado para Android 10+)
    if (Platform.isAndroid) {
        // En Android 13+ a veces no se necesita request para caché/downloads propios app
        // Pero mantenemos tu lógica básica por seguridad
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
    }

    setState(() => _isDownloading = true);

    try {
      final token = ref.read(authTokenProvider);
      
      // 2. Construir URL con Token
      final url = widget.file.fileurl.contains('?')
          ? '${widget.file.fileurl}&token=$token'
          : '${widget.file.fileurl}?token=$token';

      // 3. Directorio Temporal (Mejor que Downloads para evitar líos de permisos en Android 11+)
      final dir = await getApplicationDocumentsDirectory(); 
      final savePath = '${dir.path}/${widget.file.filename}';

      // 4. Descargar
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      // 5. Abrir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abriendo ${widget.file.filename}...')),
        );
        await OpenFilex.open(savePath);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(_getIcon(widget.file.filename), color: Colors.indigo),
        title: Text(widget.file.filename, style: const TextStyle(fontSize: 14)),
        subtitle: _isDownloading 
          ? LinearProgressIndicator(value: _progress)
          : const Text('Toca para descargar', style: TextStyle(fontSize: 12)),
        trailing: _isDownloading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download_rounded, color: Colors.grey),
        onTap: _isDownloading ? null : _downloadAndOpen,
      ),
    );
  }
}