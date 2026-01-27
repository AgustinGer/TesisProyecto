//import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Importa el paquete de permisos
import 'package:flutter_tesis/provider/auth_provider.dart';

class RecursosScreen extends ConsumerStatefulWidget {
  final List<dynamic> files;
  const RecursosScreen({super.key, required this.files});

  @override
  ConsumerState<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends ConsumerState<RecursosScreen> {
  final Map<String, double> _downloadProgress = {};

  Future<bool> _requestStoragePermission() async {
  if (await Permission.storage.isGranted) return true;

  if (await Permission.storage.request().isGranted) return true;

  if (await Permission.manageExternalStorage.isGranted) return true;

  return await Permission.manageExternalStorage.request().isGranted;
}


  // Función para solicitar permiso e iniciar la descarga
Future<void> _startDownload(String fileUrl, String filename) async {
  final granted = await _requestStoragePermission();

  if (granted) {
    await _downloadFile(fileUrl, filename);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado.')),
      );
    }
  }
}

  // Lógica de descarga (separada para mayor claridad)
  Future<void> _downloadFile(String fileUrl, String filename) async {
    final dir = await getDownloadsDirectory();

    final savePath = '${dir?.path}/$filename';
    final token = ref.read(authTokenProvider);
    if (token == null) return;
    
    final urlWithToken = fileUrl.contains('?') ? '$fileUrl&token=$token' : '$fileUrl?token=$token';

    try {
      await Dio().download(
        urlWithToken,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() { _downloadProgress[fileUrl] = received / total; });
          }
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Descarga completada: $filename'),
            action: SnackBarAction(label: 'ABRIR', onPressed: () => OpenFilex.open(savePath)),
          ),
        );
      }
    } catch (e) {
      print('Error al descargar: $e');
    } finally {
      if (mounted) setState(() { _downloadProgress.remove(fileUrl); });
    }
  }

  Icon _getFileIcon(String mimetype) {
    if (mimetype.contains('image')) return const Icon(Icons.image, color: Colors.purple);
    if (mimetype.contains('pdf')) return const Icon(Icons.picture_as_pdf, color: Colors.red);
    if (mimetype.contains('word')) return const Icon(Icons.description, color: Colors.blue);
    if (mimetype.contains('spreadsheet') || mimetype.contains('excel') || mimetype.contains('csv')) return const Icon(Icons.grid_on, color: Colors.green);
    return const Icon(Icons.attach_file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recursos')),
      body: ListView.separated(
        itemCount: widget.files.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final file = widget.files[index];
          final String filename = file['filename'] ?? 'Archivo';
          final String fileUrl = file['fileurl'] ?? '';
          final double? progress = _downloadProgress[fileUrl];

          return ListTile(
            leading: _getFileIcon(file['mimetype'] ?? ''),
            title: Text(filename),
            trailing: progress != null
                ? CircularProgressIndicator(value: progress)
                : IconButton(
                    icon: const Icon(Icons.download_for_offline_outlined),
                    onPressed: () => _startDownload(fileUrl, filename),
                  ),
          );
        },
      ),
    );
  }
}


