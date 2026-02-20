import 'dart:convert';
import 'dart:io'; // Necesario para manejar archivos (File)
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/user_profile.dart';
///import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';


class EditarPerfil extends ConsumerStatefulWidget {
  const EditarPerfil({Key? key}) : super(key: key);

  @override
  ConsumerState<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends ConsumerState<EditarPerfil> {
  final _descriptionController = TextEditingController();
  final _interestsController = TextEditingController();

  String _rawHtmlDescription = ''; // Guardará el HTML original de Moodle
  String _initialDescription = '';
  String _initialInterests = '';
  bool _hasChanges = false;
  bool _isInitialized = false;

  File? _pickedImage;
  bool _isLoading = false;
  
  bool _hasComplexMedia = false; 

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_checkForChanges);
    _interestsController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanged = _descriptionController.text != _initialDescription ||
        _interestsController.text != _initialInterests ||
        _pickedImage != null;
    if (hasChanged != _hasChanges) {
      setState(() => _hasChanges = hasChanged);
    }
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_checkForChanges);
    _interestsController.removeListener(_checkForChanges);
    _descriptionController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  // --- DETECTOR DE MULTIMEDIA ---
  bool _detectComplexMedia(String htmlContent) {
    final lowerHtml = htmlContent.toLowerCase();
    return lowerHtml.contains('<video') || 
           lowerHtml.contains('<audio') || 
           lowerHtml.contains('<iframe') || 
           lowerHtml.contains('<table') || 
           lowerHtml.contains('h5p');
  }

  // --- ABRIR WEB ---
  Future<void> _abrirEditarEnWeb() async {
    final apiUrl = ref.read(moodleApiUrlProvider);
    final userId = ref.read(userIdProvider);
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    
    final url = '$baseUrl/user/edit.php?id=$userId&course=1';
    
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el navegador web.')));
      }
    }
  }

  // --- WIDGET BOTÓN MULTIMEDIA EXTERNO ---
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
                _abrirEditarEnWeb(); 
              }
            },
          )
        ],
      ),
    );
  }

  // --- DIÁLOGO DE SALIDA ---
  Future<void> _showExitDialog() async {
    final shouldPop = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Cambios sin Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que quieres salir? Perderás los cambios no guardados.'),
        actions: [
          TextButton(
            child: const Text('Regresar', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  // --- SELECCIONAR IMAGEN ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
      _checkForChanges();
    }
  }

  // ================== FLUJO UNIFICADO DE GUARDADO ==================
  Future<void> _guardarTodo() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (_pickedImage != null) {
        await _uploadImageProcess();
      }

      if (!_hasComplexMedia && (_descriptionController.text != _initialDescription || _interestsController.text != _initialInterests)) {
        await _updateProfileTextProcess();
      }

      ref.invalidate(userProfileProvider);
      
      setState(() {
        _hasChanges = false;
        _pickedImage = null;
        _initialDescription = _descriptionController.text;
        _initialInterests = _interestsController.text;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Perfil actualizado con éxito!'), backgroundColor: Colors.green),
        );
      }

    } on SocketException catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sin conexión. Revisa tu internet.'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImageProcess() async {
    final token = ref.read(authTokenProvider);
    final userId = ref.read(userIdProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    final filename = _pickedImage!.path.split('/').last;
    final bytes = await _pickedImage!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = {
      'component': 'user',
      'filearea': 'draft',
      'itemid': '0',
      'filepath': '/',
      'filename': filename,
      'filecontent': base64Image,
      'contextlevel': 'user',
      'instanceid': userId.toString(),
    };

    final response = await http.post(
      Uri.parse('$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    final responseData = json.decode(response.body);
    if (responseData is Map && responseData.containsKey('exception')) throw Exception(responseData['message'] ?? 'Moodle rechazó la imagen.');

    final draftItemId = responseData['itemid'];

    final updateResponse = await http.post(
      Uri.parse('$apiUrl?wsfunction=core_user_update_picture&wstoken=$token&moodlewsrestformat=json'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'draftitemid': draftItemId.toString(),
        'userid': userId.toString(),
      },
    );

    final updateData = json.decode(updateResponse.body);
    if (updateData['success'] != true) throw Exception('Moodle no pudo vincular la foto.');
  }

  Future<void> _updateProfileTextProcess() async {
    final token = ref.read(authTokenProvider);
    final userId = ref.read(userIdProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);

    final response = await http.post(
      Uri.parse('$apiUrl?wsfunction=core_user_update_users&wstoken=$token&moodlewsrestformat=json'),
      body: {
        'users[0][id]': userId.toString(),
        'users[0][description]': _descriptionController.text.trim(),
        'users[0][interests]': _interestsController.text.trim(),
      },
    );

    final responseData = json.decode(response.body);
    if (responseData is List && responseData.isNotEmpty && responseData[0]['exception'] != null) {
      throw Exception(responseData[0]['message'] ?? 'Error al guardar datos de texto.');
    }
  }

  void _onLinkTapped(String? url) async {
    if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // =======================================================
  // CONSTRUCCIÓN DE LA INTERFAZ
  // =======================================================
  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(userProfileProvider);
    final token = ref.watch(authTokenProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: asyncProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error al cargar perfil:\n$err', textAlign: TextAlign.center)),
          data: (user) {
            
            if (!_isInitialized) {
              _rawHtmlDescription = user['description'] ?? '';
              _hasComplexMedia = _detectComplexMedia(_rawHtmlDescription);
              
              _initialDescription = _rawHtmlDescription.replaceAll(RegExp(r'<[^>]*>'), '').trim();
              _initialInterests = user['interests'] ?? '';
              
              _descriptionController.text = _initialDescription;
              _interestsController.text = _initialInterests;
              _isInitialized = true;
            }

            final profileImageUrl = user['profileimageurl'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- AVATAR ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.indigo.shade50,
                              border: Border.all(color: Colors.indigo.shade200, width: 3),
                              image: _pickedImage != null
                                  ? DecorationImage(image: FileImage(_pickedImage!), fit: BoxFit.cover)
                                  : (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                      ? DecorationImage(image: NetworkImage(profileImageUrl), fit: BoxFit.cover)
                                      : null,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: (_pickedImage == null && (profileImageUrl == null || profileImageUrl.isEmpty))
                                ? Icon(Icons.person, size: 70, color: Colors.indigo.shade200) : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Center(child: Text("Toca la foto para cambiarla", style: TextStyle(color: Colors.grey, fontSize: 13))),
                  
                  const SizedBox(height: 35),
                  
                  // --- CAMPO SOBRE MÍ ---
                  const Text('Sobre mí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 10),
                  
                  if (_hasComplexMedia) ...[
                    // ADVERTENCIA
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                              SizedBox(width: 10),
                              Expanded(child: Text("Tu descripción contiene contenido multimedia (videos, H5P o tablas).", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text("Para evitar borrar tu contenido interactivo accidentalmente, la edición de texto ha sido deshabilitada.", style: TextStyle(fontSize: 13, color: Colors.black54)),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.open_in_browser), label: const Text("Editar descripción en la Web"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo, side: const BorderSide(color: Colors.indigo), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              onPressed: _abrirEditarEnWeb,
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // RENDERIZADO HTML DEL PERFIL (Igual que en PageScreen/ForumScreen)
                    const Text('Vista previa de tu perfil:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Html(
                        data: _rawHtmlDescription,
                        style: {
                          "body": Style(fontSize: FontSize(15.0), margin: Margins.zero, color: Colors.black87),
                          "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
                          "iframe": Style(height: Height(200), width: Width(100, Unit.percent)),
                          "video": Style(height: Height(200), width: Width(100, Unit.percent)),
                        },
                        onLinkTap: (url, _, __) => _onLinkTapped(url),
                        extensions: [
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
                        ]
                      ),
                    ),
                  ] else ...[
                    // MODO NORMAL (SIN MULTIMEDIA)
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Escribe algo sobre ti...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 25),
                  
                  // --- CAMPO INTERESES ---
                  const Text('Intereses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _interestsController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: "Ej: Programación, Diseño, Música...",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.local_offer_outlined, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // --- BOTÓN DE GUARDAR ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_hasChanges && !_isLoading) ? _guardarTodo : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: _hasChanges ? 4 : 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
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