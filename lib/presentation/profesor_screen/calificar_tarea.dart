import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/grade_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:url_launcher/url_launcher.dart';


class PantallaCalificar extends ConsumerStatefulWidget {
  final int courseId;
  final int assignId;
  final int userId;
  final String studentName;

  const PantallaCalificar({
    super.key, 
    required this.courseId, 
    required this.assignId, 
    required this.userId, 
    required this.studentName
  });

  @override
  ConsumerState<PantallaCalificar> createState() => _PantallaCalificarState();
}

class _PantallaCalificarState extends ConsumerState<PantallaCalificar> {
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();
  final Map<String, double> _downloadProgress = {};

  // --- LÓGICA DE PERMISOS (Igual a RecursosScreen) ---
  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    return await Permission.manageExternalStorage.request().isGranted;
  }

  @override
    void dispose() {
      _gradeController.dispose();
      _feedbackController.dispose(); // No olvides liberarlo
      super.dispose();
    }
  // --- INICIAR DESCARGA ---
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

  // --- DESCARGA CON DIO Y TOKEN ---
  Future<void> _downloadFile(String fileUrl, String filename) async {
    final dir = await getDownloadsDirectory();
    final savePath = '${dir?.path}/$filename';
    final token = ref.read(authTokenProvider);
    
    if (token == null) return;
    
    // Construir URL con Token
    final urlWithToken = fileUrl.contains('?') 
        ? '$fileUrl&token=$token' 
        : '$fileUrl?token=$token';

    try {
      await Dio().download(
        urlWithToken,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() { 
              _downloadProgress[fileUrl] = received / total; 
            });
          }
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Descarga completada: $filename'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'ABRIR', 
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(savePath)
            ),
          ),
        );
      }
    } catch (e) {
      print('Error al descargar: $e');
    } finally {
      if (mounted) setState(() { _downloadProgress.remove(fileUrl); });
    }
  }

  // Función para obtener iconos según el tipo de archivo
  Icon _getFileIcon(String filename) {
    if (filename.endsWith('.pdf')) return const Icon(Icons.picture_as_pdf, color: Colors.red);
    if (filename.endsWith('.jpg') || filename.endsWith('.png')) return const Icon(Icons.image, color: Colors.purple);
    if (filename.endsWith('.docx')) return const Icon(Icons.description, color: Colors.blue);
    return const Icon(Icons.insert_drive_file, color: Colors.grey);
  }

  @override
 Widget build(BuildContext context) {
    final submissionAsync = ref.watch(submissionDetailsProvider(
      (assignId: widget.assignId, userId: widget.userId)
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('Calificar: ${widget.studentName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: submissionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final lastAttempt = data['lastattempt'] ?? {};
          final submission = lastAttempt['submission'] ?? {};
          final List plugins = submission['plugins'] ?? [];

          final filePlugin = plugins.firstWhere(
            (p) => p['type'] == 'file',
            orElse: () => null,
          );

          List files = [];
          if (filePlugin != null && filePlugin['fileareas'] != null) {
            files = filePlugin['fileareas'][0]['files'] ?? [];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Estado', submission['status'] ?? 'Sin entrega', Colors.blue),
                const SizedBox(height: 25),
                const Text('Archivos del Estudiante:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),

                if (files.isEmpty)
                  const Text('No hay archivos entregados.')
                else
                  ...files.map((file) {
                    final String filename = file['filename'];
                    final String fileUrl = file['fileurl'];
                    final double? progress = _downloadProgress[fileUrl];

                    return Card(
                      child: ListTile(
                        leading: _getFileIcon(filename),
                        title: Text(filename),
                        subtitle: Text(progress != null 
                            ? 'Descargando: ${(progress * 100).toStringAsFixed(0)}%' 
                            : 'Toca para descargar y calificar'),
                        trailing: progress != null
                            ? CircularProgressIndicator(value: progress)
                            : IconButton(
                                icon: const Icon(Icons.download_for_offline, color: Colors.indigo),
                                onPressed: () => _startDownload(fileUrl, filename),
                              ),
                      ),
                    );
                  }).toList(),

                const Divider(height: 40),
                const Text('Calificación Final (0-100)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _gradeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej: 90'),
                ),

                const SizedBox(height: 30),

// NUEVO: CAMPO DE RETROALIMENTACIÓN (OPCIONAL)
                const Text('Retroalimentación (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _feedbackController,
                  maxLines: 3, // Para que sea un cuadro de texto más grande
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Escribe un comentario para el estudiante...',
                    prefixIcon: Icon(Icons.comment_outlined),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _enviarCalificacion(context),
                    child: const Text('GUARDAR NOTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

Widget _buildInfoCard(String label, String value, Color color) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /*Future<void> _abrirArchivo(String url) async {
    final String token = ref.read(authTokenProvider)!;
    // EL TRUCO: Adjuntar el token para tener permiso de descarga
    final String urlConToken = '$url${url.contains('?') ? '&' : '?'}token=$token';

    final Uri uri = Uri.parse(urlConToken);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir la URL: $urlConToken';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el archivo: $e')),
      );
    }
  }*/

 // --- ENVIAR NOTA ---
  void _enviarCalificacion(BuildContext context) async {
    final nota = double.tryParse(_gradeController.text);
    if (nota == null || nota < 0 || nota > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota inválida')));
      return;
    }

// Mostramos cargando
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));

   /* final success = await ref.read(gradeActionsProvider).guardarNota(
      assignId: widget.assignId,
      userId: widget.userId,
      nota: nota,
    );*/

    final success = await ref.read(gradeActionsProvider).guardarNota(
      assignId: widget.assignId,
      userId: widget.userId,
      nota: nota,
      feedback: _feedbackController.text, // Enviamos el texto del nuevo controlador
    );

      if (context.mounted) {
      Navigator.pop(context); // Quitar loading
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Evaluación guardada!'), backgroundColor: Colors.green)
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar en Moodle'), backgroundColor: Colors.red)
        );
      }
    }
  }
}