//import 'package.flutter/material.dart';
//import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/provider/activity_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';


/*
class ActividadesScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int assignmentId;
  
  //const ActividadesScreen({super.key, required this.courseId, required this.assignmentId});
const ActividadesScreen({super.key, required this.courseId, required this.assignmentId});


  @override
  ConsumerState<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends ConsumerState<ActividadesScreen> {
  late final Map<String, int> _detailsProviderParams;
  
  // --- NUEVAS VARIABLES DE ESTADO ---
  //File? _pickedFile;
  List<File> _pickedFiles = [];
  bool _isUploading = false;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _detailsProviderParams = {
      'courseId': widget.courseId,
      'assignmentId': widget.assignmentId,
    };
  }

  // --- NUEVAS FUNCIONES PARA LA ENTREGA ---

  // Función para que el usuario seleccione un archivo
 /* Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
      });
    }
  }*/

  // --- FUNCIÓN PARA SELECCIONAR MÚLTIPLES ARCHIVOS ---
  
  
// --- FUNCIÓN DE SELECCIÓN CON VALIDACIONES ---
  Future<void> _pickFiles(int maxFiles, int maxSizeBytes) async {
    // Si ya alcanzamos el límite de archivos
    if (_pickedFiles.length >= maxFiles) {
      _showError('Has alcanzado el límite máximo de $maxFiles archivos.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    List<File> validNewFiles = [];
    for (var path in result.paths) {
      if (path == null) continue;
      final file = File(path);
      final size = await file.length();

      // VALIDACIÓN DE TAMAÑO (Comparar bytes)
      if (maxSizeBytes > 0 && size > maxSizeBytes) {
        _showError('El archivo ${path.split('/').last} excede el límite de tamaño.');
        continue;
      }
      
      validNewFiles.add(file);
    }

    setState(() {
      // Unir listas y respetar el máximo total
      _pickedFiles.addAll(validNewFiles);
      if (_pickedFiles.length > maxFiles) {
        _pickedFiles = _pickedFiles.sublist(0, maxFiles);
        _showError('Solo se agregaron los primeros $maxFiles archivos.');
      }
    });
  }

void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

// --- FUNCIÓN PARA SUBIR 
  Future<void> _submitAssignment() async {
    if (_pickedFiles.isEmpty) return;

    setState(() => _isUploading = true);
    final token = ref.read(authTokenProvider);
    final userId = ref.read(userIdProvider);
    final apiUrl = ref.watch(moodleApiUrlProvider);

    if (token == null || userId == null) return;

    try {
      int? draftItemId;

      print('--- INICIANDO SUBIDA MÚLTIPLE (${_pickedFiles.length} archivos) ---');

      for (var file in _pickedFiles) {
        final filename = file.path.split('/').last;
        final bytes = await file.readAsBytes();
        final base64File = base64Encode(bytes);

        final response = await http.post(
          Uri.parse('$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json'),
          body: {
            'component': 'user',
            'filearea': 'draft',
            // El primer archivo usa itemid 0, los siguientes usan el ID que Moodle nos devuelva
            'itemid': (draftItemId ?? 0).toString(),
            'filepath': '/',
            'filename': filename,
            'filecontent': base64File,
            'contextlevel': 'user',
            'instanceid': userId.toString(),
          },
        );

        final uploadData = json.decode(response.body);
        if (uploadData.containsKey('exception')) {
          throw Exception('Error al subir $filename: ${uploadData['message']}');
        }

        // Guardamos el itemid devuelto para que el siguiente archivo se suba al mismo lugar
        draftItemId = uploadData['itemid'];
        print('✅ Archivo $filename subido. draftItemId actual: $draftItemId');
      }

      // PASO FINAL: Guardar la entrega con todos los archivos agrupados
      final saveResponse = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_assign_save_submission',
          'moodlewsrestformat': 'json',
          'assignmentid': widget.assignmentId.toString(),
          'plugindata[files_filemanager]': draftItemId.toString(),
        },
      );

      print('🧾 Respuesta final: ${saveResponse.body}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Entrega múltiple exitosa!'), backgroundColor: Colors.green),
        );
        ref.invalidate(submissionStatusProvider(widget.assignmentId));
        setState(() => _pickedFiles = []);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }


  // -----------------------------------------

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'No definida';
    initializeDateFormatting('es');
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.yMMMMEEEEd('es').add_jm().format(date);
  }


  @override
  Widget build(BuildContext context) {
   final asyncDetails = ref.watch(assignmentDetailsProvider(_detailsProviderParams));
   // final asyncDetails = ref.watch(assignmentDetailsProvider({'assignmentId': widget.assignmentId}));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de la Tarea"),
      ),
      body:

      asyncDetails.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar detalles: $err')),
        data: (details) {
          final asyncStatus = ref.watch(submissionStatusProvider(widget.assignmentId));          
        //  final int dueDateTimestamp = details['duedate'] ?? 0;

                  
          final String title = details['name'] ?? 'Tarea sin título';
          final String intro = details['intro'] ?? '<p>Sin descripción.</p>';
          final int dueDate = details['duedate'] ?? 0;

                  // Convertimos el duedate de Moodle (segundos) a DateTime de Dart
          final int dueDateTimestamp = details['duedate'] ?? 0;
               //

          final DateTime dueDate2 = DateTime.fromMillisecondsSinceEpoch(dueDateTimestamp * 1000);
          // Comparamos: ¿Es "ahora" después de la "fecha límite"?
          final bool isPastDueDate = dueDateTimestamp != 0 && DateTime.now().isAfter(dueDate2);


// Dentro del data: (details) de tu assignmentDetailsProvider
          final List configs = details['configs'] ?? [];

          print("DEBUG: Configs recibidas de Moodle: $configs");

          final maxFiles = int.parse(configs.firstWhere(
            (c) => c['name'] == 'maxfilesubmissions', 
            orElse: () => {'value': '1'}
          )['value'].toString());

          final maxSizeBytes = int.parse(configs.firstWhere(
            (c) => c['name'] == 'maxsubmissionsizebytes', 
            orElse: () => {'value': '0'}
          )['value'].toString());


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                const Text('Instrucciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Html(data: intro),
                const SizedBox(height: 20),
                const Text('Fecha de entrega:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_formatTimestamp(dueDate)),
                const SizedBox(height: 20),

                // --- SECCIÓN DE ESTADO, NOTA Y FEEDBACK ---
                const Text('Estado de la calificación:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                asyncStatus.when(
                  loading: () => const Text('Cargando estado...'),
                  error: (err, stack) => Text('Error: $err'),
                  data: (statusData) {
                    final submission = statusData['lastattempt']?['submission'];
                    final status = submission?['status'] ?? 'No entregado';
                    
                    // Extraer Feedback (Nota y Comentarios)
                    final feedback = statusData['feedback'];
                    final gradeData = feedback?['grade'];
                    final List plugins = feedback?['plugins'] ?? [];

                    // Buscar el plugin de comentarios
                    final commentPlugin = plugins.firstWhere(
                      (p) => p['type'] == 'comments',
                      orElse: () => null,
                    );
                    

                    String feedbackText = '';
                    if (commentPlugin != null && commentPlugin['editorfields'] != null) {
                      feedbackText = commentPlugin['editorfields'][0]['text'] ?? '';
                    }

                    // 1. Extraemos el valor crudo y tratamos de convertirlo a un número

                   double? gradeValue;
                    String formattedGrade = 'Sin calificar';

                    if (gradeData != null && gradeData['grade'] != null) {
                      final rawGrade = gradeData['grade'];
                      gradeValue = double.tryParse(rawGrade.toString());

                      if (gradeValue != null) {
                        formattedGrade = gradeValue
                            .toStringAsFixed(2)
                            .replaceAll(RegExp(r'\.00$'), '');
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text(status == 'submitted' ? 'Entregado' : 'Pendiente de entrega'),
                          backgroundColor: status == 'submitted' ? Colors.green.shade100 : Colors.orange.shade100,
                        ),
                        
                        // Si ya hay una nota asignada, mostramos el cuadro de resultados
                       // if (gradeData != null) ...[
                          if (gradeValue != null) ...[

                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.stars, color: Colors.indigo),
                                    SizedBox(width: 8),
                                    Text('Resultado de la Evaluación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                const Divider(),
                                Text('Calificación: $formattedGrade / 100', 
                                  style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)
                                ),
                                if (feedbackText.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text('Retroalimentación del profesor:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Html(data: feedbackText),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                
                const Divider(height: 40),

                // --- UI PARA SUBIR ARCHIVO ---
                const Text('Tu entrega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                
// --- UI PARA SELECCIONAR Y LISTAR ARCHIVOS ---
                GestureDetector(
                 // onTap: (_isUploading || isPastDueDate) ? null : _pickFiles,
                //  onTap: () => _pickFiles(maxFiles, maxSizeBytes),
                  onTap: (isPastDueDate || _isUploading)
                //   onTap: (isBlockedByCutoff || _isUploading) 
                  ? null 
                  : () => _pickFiles(maxFiles, maxSizeBytes),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: _pickedFiles.isEmpty
                        ? const Column(
                            children: [
                              Icon(Icons.add_circle_outline, size: 40, color: Colors.grey),
                              Text('Toca para seleccionar archivos'),
                            ],
                          )
                        : Column(
                            children: [
                              ..._pickedFiles.map((file) => ListTile(
                                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                                title: Text(file.path.split('/').last, style: const TextStyle(fontSize: 14)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(() => _pickedFiles.remove(file)),
                                ),
                              )),
                              const Divider(),
                              const Text('Toca para añadir más archivos', style: TextStyle(color: Colors.blue, fontSize: 12)),
                            ],
                          ),
                  ),
                ), 


                const SizedBox(height: 20),

                if (isPastDueDate)

                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El plazo de entrega ha expirado. Ya no se permiten nuevas entregas.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 20),
                              
                if (_isUploading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child:
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text('ENVIAR ${_pickedFiles.length} ARCHIVOS'),
                      onPressed: (isPastDueDate || _pickedFiles.isEmpty || _isUploading) 
                    ? null 
                    : _submitAssignment,
                      // LÓGICA DE BLOQUEO:
                      // Si ya pasó la fecha OR no hay archivo seleccionado OR está subiendo: desactivar (null)
                          
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        // Estilo visual cuando está desactivado (opcional)
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 15)
                      ),
                    ) 

                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
*/

class ActividadesScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int assignmentId;
  
  const ActividadesScreen({super.key, required this.courseId, required this.assignmentId});

  @override
  ConsumerState<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends ConsumerState<ActividadesScreen> {
  late final Map<String, int> _detailsProviderParams;
  
  List<File> _pickedFiles = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _detailsProviderParams = {
      'courseId': widget.courseId,
      'assignmentId': widget.assignmentId,
    };
  }

  // --- ABRIR ACTIVIDAD EN LA WEB ---
  Future<void> _abrirActividadWeb() async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    // URL estándar de Moodle para ver una tarea específica usando 'a=' (assignment id)
    final url = '$baseUrl/mod/assign/view.php?a=${widget.assignmentId}';
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir: $e')));
      }
    }
  }

  void _onLinkTapped(String? url) async {
    if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // --- SELECCIÓN DE ARCHIVOS CON VALIDACIÓN ---
  Future<void> _pickFiles(int maxFiles, int maxSizeBytes) async {
    if (_pickedFiles.length >= maxFiles) {
      _showError('Has alcanzado el límite máximo de $maxFiles archivos.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    List<File> validNewFiles = [];
    for (var path in result.paths) {
      if (path == null) continue;
      final file = File(path);
      final size = await file.length();

      if (maxSizeBytes > 0 && size > maxSizeBytes) {
        _showError('El archivo ${path.split('/').last} excede el límite de tamaño.');
        continue;
      }
      validNewFiles.add(file);
    }

    setState(() {
      _pickedFiles.addAll(validNewFiles);
      if (_pickedFiles.length > maxFiles) {
        _pickedFiles = _pickedFiles.sublist(0, maxFiles);
        _showError('Solo se agregaron los primeros $maxFiles archivos permitidos.');
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // --- SUBIDA DE LA TAREA ---
  Future<void> _submitAssignment() async {
    if (_pickedFiles.isEmpty) return;

    setState(() => _isUploading = true);
    final token = ref.read(authTokenProvider);
    final userId = ref.read(userIdProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    if (token == null || userId == null) return;

    try {
      int? draftItemId;

      for (var file in _pickedFiles) {
        final filename = file.path.split('/').last;
        final bytes = await file.readAsBytes();
        final base64File = base64Encode(bytes);

        final response = await http.post(
          Uri.parse('$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json'),
          body: {
            'component': 'user',
            'filearea': 'draft',
            'itemid': (draftItemId ?? 0).toString(),
            'filepath': '/',
            'filename': filename,
            'filecontent': base64File,
            'contextlevel': 'user',
            'instanceid': userId.toString(),
          },
        );

        final uploadData = json.decode(response.body);
        if (uploadData.containsKey('exception')) {
          throw Exception('Error al subir $filename: ${uploadData['message']}');
        }

        draftItemId = uploadData['itemid'];
      }

      final saveResponse = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'mod_assign_save_submission',
          'moodlewsrestformat': 'json',
          'assignmentid': widget.assignmentId.toString(),
          'plugindata[files_filemanager]': draftItemId.toString(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Entrega múltiple exitosa!'), backgroundColor: Colors.green),
        );
        ref.invalidate(submissionStatusProvider(widget.assignmentId));
        setState(() => _pickedFiles = []);
      }

    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'No definida';
    initializeDateFormatting('es');
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.yMMMMEEEEd('es').add_jm().format(date);
  }

  // --- WIDGET BOTÓN MULTIMEDIA EXTERNO ---
  Widget _buildExternalContentButton(String? url, String label, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange.shade800, size: 28),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          const Text("Visualización web recomendada", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_browser, size: 16),
            label: const Text("Ver en Navegador"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(200, 36)),
            onPressed: () async {
              if (url != null && url.isNotEmpty) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              } else {
                _abrirActividadWeb(); 
              }
            },
          )
        ],
      ),
    );
  }

  // --- MOTOR HTML REUTILIZABLE ---
  // Extraemos las extensiones a una función para aplicarlas tanto a las instrucciones como al feedback
  List<HtmlExtension> _getHtmlExtensions(String? token) {
    return [
      TagExtension(
        tagsToExtend: {"table"},
        builder: (ctx) => _buildExternalContentButton(null, "Tabla de Datos Compleja", Icons.table_chart_rounded),
      ),
      TagExtension(
        tagsToExtend: {"audio"},
        builder: (ctx) {
            final element = ctx.element;
            String src = element?.attributes['src'] ?? "";
            if (src.isEmpty && element != null) {
            for (var child in element.children) {
              if (child.localName == 'source') src = child.attributes['src'] ?? "";
            }
          }
          return _buildExternalContentButton(src.isNotEmpty ? src : null, "Audio / Grabación", Icons.audiotrack_rounded);
        },
      ),
      TagExtension(
        tagsToExtend: {"video"},
        builder: (ctx) {
          final element = ctx.element;
          String src = element?.attributes['src'] ?? "";
          if (src.isEmpty && element != null) {
            for (var child in element.children) {
              if (child.localName == 'source') src = child.attributes['src'] ?? "";
            }
          }
          if (src.isNotEmpty && YoutubePlayer.convertUrlToId(src) != null) {
            return EmbeddedYoutubePlayer(url: src);
          }
          return _buildExternalContentButton(src, "Video Formato Web", Icons.videocam_off);
        },
      ),
      TagExtension(
        tagsToExtend: {"iframe"},
        builder: (ctx) {
          final element = ctx.element;
          String src = element?.attributes['src'] ?? "";
          if (src.startsWith('//')) src = 'https:$src';
          if (YoutubePlayer.convertUrlToId(src) != null) {
            return EmbeddedYoutubePlayer(url: src);
          }
          return _buildExternalContentButton(src, "Contenido Interactivo", Icons.touch_app);
        },
      ),
      TagExtension(
        tagsToExtend: {"math"},
        builder: (ctx) => _buildExternalContentButton(null, "Ecuación Matemática", Icons.functions_rounded),
      ),
      TagExtension(
        tagsToExtend: {"time"},
        builder: (ctx) {
          final dateText = ctx.element?.text ?? "Fecha";
          return _buildExternalContentButton(null, "Dato de Tiempo: $dateText", Icons.access_time_filled_rounded);
        },
      ),
      TagExtension(
        tagsToExtend: {"object", "embed"},
        builder: (ctx) {
          final element = ctx.element;
          String src = element?.attributes['src'] ?? element?.attributes['data'] ?? "";
          return _buildExternalContentButton(src.isNotEmpty ? src : null, "Objeto Multimedia", Icons.extension_rounded);
        },
      ),
      TagExtension(
        tagsToExtend: {"img"},
        builder: (ctx) {
          String src = ctx.element?.attributes['src'] ?? "";
          if (src.contains('pluginfile.php') && !src.contains('token=')) { 
            src = src.contains('?') ? '$src&token=$token' : '$src?token=$token'; 
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(src, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey))
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetails = ref.watch(assignmentDetailsProvider(_detailsProviderParams));
    final token = ref.watch(authTokenProvider);
    
    // Estilo global base para el renderizado de HTML
    final globalHtmlStyle = {
      "body": Style(fontSize: FontSize(15.0), margin: Margins.zero, color: Colors.black87),
      "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
      "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
      "video": Style(height: Height(200), width: Width(100, Unit.percent)),
    };

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo limpio
      appBar: AppBar(
        title: const Text("Detalle de la Tarea", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Abrir en navegador',
            onPressed: _abrirActividadWeb,
          ),
        ],
      ),
      body: asyncDetails.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar detalles: $err')),
        data: (details) {
          final asyncStatus = ref.watch(submissionStatusProvider(widget.assignmentId));          
                  
          final String title = details['name'] ?? 'Tarea sin título';
          final String intro = details['intro'] ?? '<p>Sin descripción.</p>';
          final int dueDateTimestamp = details['duedate'] ?? 0;

          final DateTime dueDate2 = DateTime.fromMillisecondsSinceEpoch(dueDateTimestamp * 1000);
          final bool isPastDueDate = dueDateTimestamp != 0 && DateTime.now().isAfter(dueDate2);

          final List configs = details['configs'] ?? [];
          final maxFiles = int.parse(configs.firstWhere((c) => c['name'] == 'maxfilesubmissions', orElse: () => {'value': '1'})['value'].toString());
          final maxSizeBytes = int.parse(configs.firstWhere((c) => c['name'] == 'maxsubmissionsizebytes', orElse: () => {'value': '0'})['value'].toString());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- CABECERA DE LA TAREA ---
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo.shade100)),
                  child: Row(
                    children: [
                      Icon(Icons.event_available, color: Colors.indigo.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              const TextSpan(text: 'Fecha de entrega: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: _formatTimestamp(dueDateTimestamp)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                const Text('Instrucciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                const SizedBox(height: 8),
                
                // --- RENDERIZADO SEGURO DE INSTRUCCIONES ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Html(
                    data: intro,
                    style: globalHtmlStyle,
                    onLinkTap: (url, _, __) => _onLinkTapped(url),
                    extensions: _getHtmlExtensions(token), // Inyectamos nuestro motor
                  ),
                ),
                
                const SizedBox(height: 30),

                // --- SECCIÓN DE ESTADO, NOTA Y FEEDBACK ---
                const Text('Estado de la entrega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                const SizedBox(height: 10),
                
                asyncStatus.when(
                  loading: () => const Text('Cargando estado...', style: TextStyle(color: Colors.grey)),
                  error: (err, stack) => Text('Error al cargar estado: $err', style: const TextStyle(color: Colors.red)),
                  data: (statusData) {
                    final submission = statusData['lastattempt']?['submission'];
                    final status = submission?['status'] ?? 'No entregado';
                    
                    final feedback = statusData['feedback'];
                    final gradeData = feedback?['grade'];
                    final List plugins = feedback?['plugins'] ?? [];

                    final commentPlugin = plugins.firstWhere((p) => p['type'] == 'comments', orElse: () => null);
                    
                    String feedbackText = '';
                    if (commentPlugin != null && commentPlugin['editorfields'] != null) {
                      feedbackText = commentPlugin['editorfields'][0]['text'] ?? '';
                    }

                    double? gradeValue;
                    String formattedGrade = 'Sin calificar';

                    if (gradeData != null && gradeData['grade'] != null) {
                      final rawGrade = gradeData['grade'];
                      gradeValue = double.tryParse(rawGrade.toString());

                      if (gradeValue != null) {
                        formattedGrade = gradeValue.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          avatar: Icon(status == 'submitted' ? Icons.check_circle : Icons.pending, color: status == 'submitted' ? Colors.green.shade700 : Colors.orange.shade700, size: 18),
                          label: Text(status == 'submitted' ? 'Entregado' : 'Pendiente de entrega', style: TextStyle(color: status == 'submitted' ? Colors.green.shade900 : Colors.orange.shade900, fontWeight: FontWeight.bold)),
                          backgroundColor: status == 'submitted' ? Colors.green.shade100 : Colors.orange.shade100,
                          side: BorderSide.none,
                        ),
                        
                        // --- CUADRO DE CALIFICACIÓN Y FEEDBACK ---
                        if (gradeValue != null) ...[
                          const SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200, width: 2),
                              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.verified, color: Colors.green.shade600),
                                    const SizedBox(width: 8),
                                    const Text('Calificación Final', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Spacer(),
                                    Text('$formattedGrade / 100', style: TextStyle(fontSize: 18, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (feedbackText.isNotEmpty) ...[
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                                  const Text('Retroalimentación del profesor:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                  const SizedBox(height: 8),
                                  
                                  // --- RENDERIZADO SEGURO DE FEEDBACK ---
                                  Html(
                                    data: feedbackText,
                                    style: globalHtmlStyle,
                                    onLinkTap: (url, _, __) => _onLinkTapped(url),
                                    extensions: _getHtmlExtensions(token), // Inyectamos nuestro motor al feedback
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 30),

                // --- UI PARA SUBIR ARCHIVO ---
                const Text('Tu Entrega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: (isPastDueDate || _isUploading) ? null : () => _pickFiles(maxFiles, maxSizeBytes),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: (isPastDueDate) ? Colors.grey.shade200 : Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isPastDueDate) ? Colors.grey.shade300 : Colors.indigo.shade200, style: BorderStyle.solid, width: 2)
                    ),
                    child: _pickedFiles.isEmpty
                        ? Column(
                            children: [
                              Icon(Icons.cloud_upload_rounded, size: 50, color: (isPastDueDate) ? Colors.grey : Colors.indigo.shade300),
                              const SizedBox(height: 10),
                              Text(
                                (isPastDueDate) ? 'Las entregas están cerradas' : 'Toca aquí para seleccionar archivos',
                                style: TextStyle(color: (isPastDueDate) ? Colors.grey : Colors.indigo.shade700, fontWeight: FontWeight.bold),
                              ),
                              if (!isPastDueDate)
                                Text('Máximo $maxFiles archivos permitidos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        : Column(
                            children: [
                              ..._pickedFiles.map((file) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                child: ListTile(
                                  leading: const Icon(Icons.insert_drive_file, color: Colors.indigo),
                                  title: Text(file.path.split('/').last, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    onPressed: () => setState(() => _pickedFiles.remove(file)),
                                  ),
                                ),
                              )),
                              if (_pickedFiles.length < maxFiles)
                                TextButton.icon(
                                  onPressed: () => _pickFiles(maxFiles, maxSizeBytes),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Añadir más archivos'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                                )
                            ],
                          ),
                  ),
                ), 

                if (isPastDueDate)
                  Container(
                    margin: const EdgeInsets.only(top: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade100)),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El plazo de entrega ha expirado. Ya no se permiten nuevas entregas o modificaciones.',
                            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 25),
                              
                if (_isUploading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: Text('ENVIAR ${_pickedFiles.length} ARCHIVO${_pickedFiles.length == 1 ? '' : 'S'}', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      onPressed: (isPastDueDate || _pickedFiles.isEmpty || _isUploading) ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: (_pickedFiles.isEmpty || isPastDueDate) ? 0 : 4,
                      ),
                    ) 
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- CLASE PARA YOUTUBE ---
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