//import 'package.flutter/material.dart';
//import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/provider/activity_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
//import 'package.intl/intl.dart';
//import 'package:flutter_tesis/providers/assignment_provider.dart';


import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Asegúrate de que las rutas a tus providers sean correcta

import 'package:flutter_tesis/provider/auth_provider.dart';
//import 'package:open_filex/open_filex.dart';
//import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';


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

  /*Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true, // Permitir varios a la vez
    );

    if (result != null) {
      setState(() {
        // Agregamos los nuevos archivos a los que ya estaban (sin duplicar rutas)
        final newFiles = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
        
        _pickedFiles.addAll(newFiles);
      });
    }
  }*/

  // Función para subir el archivo y confirmar la entrega

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
          /*final int cutoffDateTimestamp = details['cutoffdate'] ?? 0; // NUEVO
          final DateTime now = DateTime.now().toUtc();
          final DateTime dueDateTime = DateTime.fromMillisecondsSinceEpoch(dueDateTimestamp * 1000);
          final DateTime cutoffDateTime = DateTime.fromMillisecondsSinceEpoch(cutoffDateTimestamp * 1000);*/

          // LÓGICA DE ESTADOS
          // 1. ¿Ya pasó la fecha de entrega? (Pero aún puede entregar si no hay corte)
       //   final bool isLate = dueDateTimestamp != 0 && now.isAfter(dueDateTime);
          
          // 2. ¿Ya pasó la fecha de corte? (Bloqueo total)
       //   final bool isBlockedByCutoff = cutoffDateTimestamp != 0 && now.isAfter(cutoffDateTime);

          final DateTime dueDate2 = DateTime.fromMillisecondsSinceEpoch(dueDateTimestamp * 1000);
          // Comparamos: ¿Es "ahora" después de la "fecha límite"?
          final bool isPastDueDate = dueDateTimestamp != 0 && DateTime.now().isAfter(dueDate2);


// Dentro del data: (details) de tu assignmentDetailsProvider
          final List configs = details['configs'] ?? [];

          print("DEBUG: Configs recibidas de Moodle: $configs");
         // final maxFiles = int.parse(configs.firstWhere((c) => c['name'] == 'maxattachments', orElse: () => {'value': '1'})['value']);
         // final maxSizeBytes = int.parse(configs.firstWhere((c) => c['name'] == 'maxsubmissionsizebytes', orElse: () => {'value': '0'})['value']);

          // EXTRAER ARCHIVOS ENVIADOS
          // Buscamos el plugin de tipo 'file' que contiene los documentos
// Buscamos el valor usando el nombre exacto que aparece en tu log: 'maxfilesubmissions'
          final maxFiles = int.parse(configs.firstWhere(
            (c) => c['name'] == 'maxfilesubmissions', 
            orElse: () => {'value': '1'}
          )['value'].toString());

          final maxSizeBytes = int.parse(configs.firstWhere(
            (c) => c['name'] == 'maxsubmissionsizebytes', 
            orElse: () => {'value': '0'}
          )['value'].toString());

          // También puedes extraer los tipos permitidos (en tu log sale "*", que es "todos")
       /*   final acceptedTypes = configs.firstWhere(
            (c) => c['name'] == 'filetypeslist', 
            orElse: () => {'value': '*'}
          )['value'].toString();*/

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
                    final rawGrade = gradeData['grade'];
                    double? gradeValue = double.tryParse(rawGrade.toString());

                    // 2. Creamos un String formateado
                    // Si el valor es nulo (no hay nota), mostramos '0'
                    // Si no, lo limitamos a 2 decimales y quitamos ceros innecesarios al final
                    String formattedGrade = gradeValue != null 
                        ? gradeValue.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '') 
                        : '0';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text(status == 'submitted' ? 'Entregado' : 'Pendiente de entrega'),
                          backgroundColor: status == 'submitted' ? Colors.green.shade100 : Colors.orange.shade100,
                        ),
                        
                        // Si ya hay una nota asignada, mostramos el cuadro de resultados
                        if (gradeData != null) ...[
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


              /*  GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: Center(
                      child: _pickedFile == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.file_upload_outlined, size: 40, color: Colors.grey),
                              Text('Seleccionar archivo para entregar'),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 40, color: Colors.green),
                              Text(_pickedFile!.path.split('/').last),
                            ],
                          ),
                    ),
                  ),
                ),*/


                const SizedBox(height: 20),

                if (isPastDueDate)
                /*if (isBlockedByCutoff) 
                  _buildAlertBanner(
                    Icons.lock_clock, 
                    Colors.red, 
                    'El plazo de entrega ha cerrado definitivamente el ${_formatTimestamp(cutoffDateTimestamp)}.'
                  )
                else if (isLate)
                  _buildAlertBanner(
                    Icons.warning_amber_rounded, 
                    Colors.orange, 
                    'La fecha límite fue el ${_formatTimestamp(dueDateTimestamp)}. Tu entrega se marcará como retrasada.'
                  ),*/
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
                     // label: Text(_isUploading ? 'Enviando...' : 'REALIZAR ENTREGA'),
                      label: Text('ENVIAR ${_pickedFiles.length} ARCHIVOS'),
                      //onPressed: _pickedFiles.isEmpty ? null : _submitAssignment,
                      onPressed: (isPastDueDate || _pickedFiles.isEmpty || _isUploading) 
                      // onPressed: (isBlockedByCutoff || _pickedFiles.isEmpty || _isUploading) 
                    ? null 
                    : _submitAssignment,
                      // LÓGICA DE BLOQUEO:
                      // Si ya pasó la fecha OR no hay archivo seleccionado OR está subiendo: desactivar (null)
                    //  onPressed: (isPastDueDate || _pickedFile == null || _isUploading) 
                    /*     ? null*/ 
                    //      : _submitAssignment,
                          
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

                    /*ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('ENVIAR TAREA'),
                      onPressed: _pickedFile == null ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white
                      ),
                    ),*/
      /*asyncDetails.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar detalles: $err')),
        data: (details) {
      
       final asyncStatus = ref.watch(submissionStatusProvider(widget.assignmentId));
          
          final String title = details['name'] ?? 'Tarea sin título';
          final String intro = details['intro'] ?? '<p>Sin descripción.</p>';
          final int dueDate = details['duedate'] ?? 0;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                const Text('Instrucciones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Html(data: intro),
                const SizedBox(height: 20),
                const Text('Fecha de entrega:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_formatTimestamp(dueDate)),
                const SizedBox(height: 20),
                
                const Text('Estado de la entrega:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                asyncStatus.when(
                  loading: () => const Text('Cargando estado...'),
                  error: (err, stack) => Text('Error: $err'),
                  data: (statusData) {
                    final status = statusData['lastattempt']?['submission']?['status'] ?? 'No entregado';
                    return Chip(
                      label: Text(status == 'submitted' ? 'Entregado' : 'No entregado'),
                      backgroundColor: status == 'submitted' ? Colors.green.shade100 : Colors.orange.shade100,
                    );
                  }
                ),
                
                const Divider(height: 30),

                // --- NUEVA SECCIÓN DE UI PARA LA ENTREGA ---
                const Text('Entrega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid)
                    ),
                    child: Center(
                      child: _pickedFile == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Toca para seleccionar un archivo'),
                            ],
                          )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.insert_drive_file, size: 50, color: Colors.blue),
                            const SizedBox(height: 8),
                            Text(_pickedFile!.path.split('/').last, textAlign: TextAlign.center),
                          ],
                        ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isUploading)
                  const Center(child: CircularProgressIndicator())
                else
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Realizar entrega'),
                      onPressed: _pickedFile == null ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
                      ),
                    ),
                  )
                // ------------------------------------------
              ],
            ),
          );
        },
      ),
    );*/
  }


 /*Widget _buildAlertBanner(IconData icon, Color color, String message) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    ),
  );
 }*/
}
