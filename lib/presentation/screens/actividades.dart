import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/provider/activity_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:flutter_tesis/provider/assignment_provider.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';

class ActividadesScreen extends ConsumerStatefulWidget { 
  final int courseId;// Cambiado a ConsumerStatefulWidget
  final int assignmentId;
 const ActividadesScreen({super.key, required this.courseId, required this.assignmentId});

  @override
  ConsumerState<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends ConsumerState<ActividadesScreen> {
  File? _pickedFile; // Para guardar el archivo seleccionado
  bool _isUploading = false; // Para mostrar el spinner de carga

  // Función para que el usuario seleccione un archivo
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
      });
    }
  }

  // Función para subir el archivo y confirmar la entrega
  Future<void> _submitAssignment() async {
    if (_pickedFile == null) return;

    setState(() { _isUploading = true; });

    final token = ref.read(authTokenProvider);
    const apiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';

    try {
      // --- PASO 1: Subir el archivo al área de borradores ---
      final uploadUrl = '$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json';
      var uploadRequest = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields.addAll({
          'component': 'assignsubmission_file', // Componente específico para entregas de tareas
          'filearea': 'submission_files',
          'itemid': '0', // Se usa 0 para crear un nuevo borrador
          'filepath': '/',
          'filename': _pickedFile!.path.split('/').last,
        })
        ..files.add(await http.MultipartFile.fromPath('file_0', _pickedFile!.path));

      final uploadResponse = await uploadRequest.send();
      final uploadResponseBody = await uploadResponse.stream.bytesToString();

      if (uploadResponse.statusCode != 200) throw Exception('Error al subir el archivo: $uploadResponseBody');
      
      final uploadData = json.decode(uploadResponseBody);
      if (uploadData is List && uploadData.isNotEmpty && uploadData[0].containsKey('itemid')) {
        final int draftItemId = uploadData[0]['itemid'];

        // --- PASO 2: Guardar la entrega asociando el archivo subido ---
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

        if (saveResponse.statusCode != 200) throw Exception('Error al guardar la entrega');

        // Si todo va bien, invalida el provider para refrescar la pantalla
        ref.invalidate(assignmentProvider({
          'courseId': widget.courseId,
          'assignmentId': widget.assignmentId
        }));
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('¡Tarea entregada con éxito!'), backgroundColor: Colors.green)
           );
        }

      } else {
        throw Exception('La respuesta de la subida del archivo no es válida: $uploadResponseBody');
      }

    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
         );
      }
    } finally {
      if(mounted) setState(() { _isUploading = false; });
    }
  }


  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'No definida';
    initializeDateFormatting('es');
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.yMMMMEEEEd('es').add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
      final asyncAssignment = ref.watch(assignmentProvider({
        'courseId': widget.courseId,
        'assignmentId': widget.assignmentId
      }));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de la Tarea"),
      ),
      body: asyncAssignment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
           final String title = data['name'];
          final String intro = data['intro'];
          final int dueDate = data['duedate'];
          final String status = data['status'];
          
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
                Chip(
                  label: Text(status == 'submitted' ? 'Entregado' : 'No entregado'),
                  backgroundColor: status == 'submitted' ? Colors.green.shade100 : Colors.orange.shade100,
                ),
                
                const Divider(height: 30),

                // --- NUEVA SECCIÓN DE ENTREGA ---
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
                      // El botón se deshabilita si no hay archivo seleccionado
                      onPressed: _pickedFile == null ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
                      ),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}

/*class Actividades extends StatelessWidget {
  const Actividades({super.key});

  @override
  Widget build(BuildContext context) {
     final colors= Theme.of(context).colorScheme;
      return Scaffold(
      appBar: AppBar(
        
        //backgroundColor: colors.primary,
        title: Text('ACTIVIDADES'),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: colors.secondary
                )                
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Actividad 1: Algoritmo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),

            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Realize un algoritmo FIFO en C++'),
              ),
            ),

            SizedBox(height: 10),

             Container(
              width: double.infinity,
              decoration: BoxDecoration(
                
                border: Border.all(
                  width: 1,
                  color: colors.secondary
                )                
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Entrega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),
            
            SizedBox(height: 10),

            

             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10),
               child: Container(
                          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: BorderDirectional(bottom: BorderSide(color: Colors.grey,width: 1)
                  )                
                ),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Text('Fecha de entrega: 24/05/2025, 23:59', ),
                           ),
                           ),
             ),

            SizedBox(height: 10),

            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10),
               child: Container(
                          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: BorderDirectional(bottom: BorderSide(color: Colors.grey,width: 1)
                  )                
                ),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Text('Tiempo restante: tres dias y 6 horas', ),
                  ),
                ),
             ),

             SizedBox(height: 30),


             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10),
               child: GestureDetector(
                    onTap: () {
                      
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey,
                          width: 2
                        )
                      ),
               
                    child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                        Icon(Icons.cloud_upload_outlined, size: 60,color: Colors.white),
                        SizedBox(height: 8),
                        Text('toque para subir el archivo')
                       ],
                      ),
                    ),
                  ),
             ),

                SizedBox(height: 10),
                
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: (){}, 
                        child: Text('Guardar')),
                /*      ElevatedButton(
                        onPressed: (){}, 
                        child: Text('Guardar')),*/
                    ],
                  ),
                ),

             SizedBox(height: 10),

             Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: colors.secondary
                )                
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Nota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),
            
            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Calificación: 18'),
              ),
            ),
          ],
        ))// ListInicio(),
    );
  }
}*/