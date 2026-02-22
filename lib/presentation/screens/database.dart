import 'dart:convert';
import 'dart:io';
import 'package:flutter_tesis/presentation/calificar_database_modal.dart';
import 'package:flutter_tesis/presentation/comentarios_database_modal.dart';
import 'package:flutter_tesis/provider/database_config_provider.dart';
//import 'package:flutter_tesis/provider/teacher_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/presentation/screens/agregar_basedatos.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/database_provider.dart';
import 'package:intl/intl.dart'; // Agrega intl en pubspec.yaml para formatear fechas

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';


class DatabaseScreen extends ConsumerStatefulWidget {
  final int databaseInstanceId;
  final String title;
  
  // --- CAMPOS NUEVOS PARA CALIFICACIÓN ---
  final int moduleId;        // CMID
  final int moduleContextId; // Context ID (Vital para calificar)
  final int courseId;        // ID del curso
  final bool isTeacher;      // Rol del usuario

  const DatabaseScreen({
    super.key,
    required this.databaseInstanceId,
    required this.title,
    required this.moduleId,
    required this.moduleContextId,
    required this.courseId,
    required this.isTeacher,
  });

  @override
  ConsumerState<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends ConsumerState<DatabaseScreen> {
  final Map<String, double> _downloadProgress = {};


  //final Map<int, String> _localRatings = {};

  // ... (TUS FUNCIONES DE PERMISOS Y DESCARGA SE MANTIENEN IGUAL) ...
  // [CÓDIGO DE _requestStoragePermission, _getDownloadPath, _startDownload, _downloadFile]
  // (Omití pegarlas de nuevo para no hacer gigante la respuesta, usa las del chat anterior)
   Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
       if (await Permission.storage.request().isGranted) return true;
       if (await Permission.manageExternalStorage.request().isGranted) return true;
       if (await Permission.photos.request().isGranted) return true;
    }
    return true; 
  }

  Future<String?> _getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) directory = await getExternalStorageDirectory();
      }
    } catch (err) { print("Error: $err"); }
    return directory?.path;
  }

  Future<void> _startDownload(String fileUrl, String filename) async {
    if (await _requestStoragePermission()) await _downloadFile(fileUrl, filename);
  }

  Future<void> _downloadFile(String fileUrl, String filename) async {
    final saveDir = await _getDownloadPath();
    if (saveDir == null) return;
    final savePath = '$saveDir/$filename';
    final token = ref.read(authTokenProvider);
    if (token == null) return;
    final urlWithToken = fileUrl.contains('?') ? '$fileUrl&token=$token' : '$fileUrl?token=$token';

    setState(() => _downloadProgress[fileUrl] = 0.01);
    try {
      await Dio().download(urlWithToken, savePath, onReceiveProgress: (r, t) {
        if (t != -1) setState(() => _downloadProgress[fileUrl] = r / t);
      });
      if (mounted) {
        setState(() => _downloadProgress.remove(fileUrl));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Descargado: $filename'), backgroundColor: Colors.green,
          action: SnackBarAction(label: 'ABRIR', textColor: Colors.white, onPressed: () => OpenFilex.open(savePath)),
        ));
      }
    } catch (e) {
      if (mounted) {
         setState(() => _downloadProgress.remove(fileUrl));
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
  // ... (FIN FUNCIONES DESCARGA) ...


  @override
  Widget build(BuildContext context) {
    // 1. CARGAMOS ENTRADAS
    final entriesAsync = ref.watch(databaseEntriesProvider(widget.databaseInstanceId));
// CORRECCIÓN DEL BUCLE: Creamos una llave única tipo String
    final configKey = '${widget.courseId}-${widget.databaseInstanceId}';
    // Llamamos al provider usando esa llave
    final configAsync = ref.watch(databaseConfigProvider(configKey));

    final myUserId = ref.read(userIdProvider);


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: _downloadProgress.isNotEmpty 
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.indigo))
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // ... Tu navegación a AgregarBaseDatosScreen ...
           final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgregarBaseDatosScreen(databaseId: widget.databaseInstanceId),
            ),
          );
          if (result == true) ref.invalidate(databaseEntriesProvider(widget.databaseInstanceId));
        },
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) return const Center(child: Text('No hay registros.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
             // final bool isMe = (entry.userId == myUserId);
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    collapsedShape: const Border(),
                    shape: const Border(),
                    
                    subtitle: configAsync.when(
                    data: (config) {
                      // Condiciones para mostrar el botón
                      //final bool showRating = widget.isTeacher && config.ratingsEnabled; // && !isMe;
                      final bool isMe = (entry.userId == myUserId);
                      
                      // Condición para CALIFICAR
                      final bool canRate = widget.isTeacher && config.ratingsEnabled && !isMe;



                      
                      // 🔥 NUEVO: Verificamos si ya la calificamos en esta sesión
                      final localRatings = ref.watch(localRatingsCacheProvider);
                      final String? assignedGrade = localRatings[entry.id];
                      final bool isGraded = assignedGrade != null;

                      return Row(
                        children: [
                          
                          // 1. BOTÓN COMENTARIOS (Visible para todos, usualmente)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text("Comentar"),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => ComentariosDataBaseModal(
                                  entryId: entry.id,
                                moduleId: widget.moduleId,
                                //  contextId: widget.moduleContextId, // Usamos el ContextID aquí
                                ),
                              );
                            },
                          ),

                          const Spacer(), // Empuja el botón de calificar a la derecha

                          // 2. BOTÓN CALIFICAR (Solo si cumple condiciones)
                          if (canRate)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                //backgroundColor: Colors.orange.shade100,
                                //foregroundColor: Colors.orange.shade900,

                                backgroundColor: isGraded ? Colors.green.shade100 : Colors.orange.shade100,
                                foregroundColor: isGraded ? Colors.green.shade900 : Colors.orange.shade900,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                visualDensity: VisualDensity.compact,
                              ),
                            
                              icon: Icon(isGraded ? Icons.check_circle : Icons.star, size: 16),
                              label: Text(isGraded ? "Nota: $assignedGrade" : "Calificar"),

                            //  icon: const Icon(Icons.star, size: 16),
                            //  label: const Text("Calificar"),
                             /* onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => CalificarDataBaseModal(
                                    moduleId: widget.moduleId,  // CMID
                                    entryId: entry.id,
                                    ratedUserId: entry.userId,
                                    studentName: 'Estudiante',
                                    scaleId: config.scale == 0 ? 100 : config.scale,
                                  ),
                                );
                              },*/

                              onPressed: () async {
                                // Guardamos el resultado (la nota) que devuelve el modal al cerrarse
                                final result = await showModalBottomSheet<String>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => CalificarDataBaseModal(
                                    moduleId: widget.moduleId,  
                                    entryId: entry.id,
                                    ratedUserId: entry.userId,
                                    studentName: 'Estudiante',
                                    scaleId: config.scale == 0 ? 100 : config.scale,
                                  ),
                                );

                                // Si el modal devolvió una nota (no se canceló), la guardamos
                                if (result != null) {
                                 ref.read(localRatingsCacheProvider.notifier).update((state) {
                                    // Clonamos el mapa actual y le agregamos la nueva nota
                                    return {...state, entry.id: result};
                                 // setState(() {
                                 //   localRatings[entry.id] = result;
                                  });
                                }
                              },
                            ),
                        ],
                      );
                    },
                                        
                      
                    loading: () => const Text("Cargando...", style: TextStyle(fontSize: 10)),
                    error: (_,__) => const SizedBox.shrink(),
                  ),
                    // HEADER (Widget de usuario creado antes)
                    title: UserHeaderWidget(
                      userId: entry.userId,
                      timeCreated: entry.timeCreated,
                    ),

                    children: [
                      const Divider(thickness: 1, height: 20),
                      
                      // --- CAMPOS DE LA BASE DE DATOS ---
                      ...entry.fields.entries.map((field) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(field.key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo.shade700)),
                              const SizedBox(height: 6),
                              
                              // HTML CON LÓGICA DE DESCARGA
                              Html(
                                data: field.value,
                                style: {
                                  "body": Style(margin: Margins.zero, fontSize: FontSize(15)),
                                  "img": Style(width: Width(100, Unit.percent), padding: HtmlPaddings.symmetric(vertical: 8)),
                                  "a": Style(textDecoration: TextDecoration.none, color: Colors.indigo, fontWeight: FontWeight.w600, fontSize: FontSize(16)),
                                },
                                onLinkTap: (url, attributes, element) async {
                                  if (url == null) return;
                                  // (Lógica de descarga inteligente que te pasé en el mensaje anterior)
                                  // ... Copia aquí el bloque onLinkTap inteligente ...
                                   bool isFile = false;
                                   final String lowerUrl = url.toLowerCase();
                                   if (lowerUrl.contains('pluginfile.php') || lowerUrl.contains('draftfile.php')) isFile = true;
                                   // ... validación de extensión ...
                                   if (isFile) {
                                      String filename = element?.text.trim() ?? 'archivo';
                                      if (filename.isEmpty || filename.contains('/')) filename = 'archivo_descargado';
                                      filename = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                                      await _startDownload(url, filename);
                                   } else {
                                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                   }
                                },
                                extensions: [
                                  TagExtension(
                                    tagsToExtend: {"img"},
                                    builder: (extensionContext) {
                                      final element = extensionContext.element;
                                      String? src = element?.attributes['src'];
                                      if (src != null && !src.contains('token=')) {
                                         final token = ref.read(authTokenProvider); 
                                         src = '$src?token=$token'; 
                                      }
                                      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(src ?? '', fit: BoxFit.cover));
                                    },
                                  ),
                                ],
                              ),
                              // Barra de progreso mini
                              Builder(builder: (context) {
                                  final activeUrl = _downloadProgress.keys.firstWhere((u) => field.value.contains(u), orElse: () => '');
                                  if (activeUrl.isNotEmpty) {
                                    return LinearProgressIndicator(value: _downloadProgress[activeUrl], minHeight: 4);
                                  }
                                  return const SizedBox.shrink();
                              })
                            ],
                          ),
                        );
                      }),
            
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class UserHeaderWidget extends ConsumerStatefulWidget {
  final int userId;
  final String timeCreated;

  const UserHeaderWidget({super.key, required this.userId, required this.timeCreated});

  @override
  ConsumerState<UserHeaderWidget> createState() => _UserHeaderWidgetState();
}

class _UserHeaderWidgetState extends ConsumerState<UserHeaderWidget> {
  String? _fullName;
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  String _formatDate(String timestampString) {
    if (timestampString.isEmpty) return '';
    
    // 1. Intentamos convertir el String a int
    final timestamp = int.tryParse(timestampString);
    
    // Si falla la conversión o es null, devolvemos vacío
    if (timestamp == null) return '';

    // 2. Moodle usa segundos, Dart usa milisegundos -> x1000
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    
    // 3. Formateamos
    // Asegúrate de tener import 'package:intl/intl.dart';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Future<void> _fetchUserData() async {

    // 2. Si es otro usuario, consultamos a Moodle
    try {
      final token = ref.read(authTokenProvider);
      final apiUrl = ref.read(moodleApiUrlProvider);
      
      // Usamos la función core_user_get_users_by_field para obtener info por ID
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'core_user_get_users_by_field',
          'moodlewsrestformat': 'json',
          'field': 'id',
          'values[0]': widget.userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // La respuesta es una lista de usuarios
        if (data is List && data.isNotEmpty) {
          final user = data[0];
          if (mounted) {
            setState(() {
              _fullName = user['fullname'];
              _profileImageUrl = user['profileimageurl'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error cargando usuario: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _fullName ?? 'Usuario ${widget.userId}';
    
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
          child: _profileImageUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isLoading 
                ? Container(width: 100, height: 10, color: Colors.grey.shade200) // Skeleton loading
                : Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
              Text(
                _formatDate(widget.timeCreated),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}