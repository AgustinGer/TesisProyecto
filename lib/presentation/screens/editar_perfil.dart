import 'dart:convert';
import 'dart:io'; // Necesario para manejar archivos (File)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/user_profile.dart';
///import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Importa tus providers
//import 'package:flutter_tesis/providers/auth_provider.dart';
//import 'package:flutter_tesis/providers/user_profile_provider.dart';

//import 'dart:convert';
//import 'dart:io';
// Función para actualizar datos en Moodle

// Ajusta según tu proyecto
class EditarPerfil extends ConsumerStatefulWidget {
  const EditarPerfil({Key? key}) : super(key: key);

  @override
  ConsumerState<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends ConsumerState<EditarPerfil> {
  final _descriptionController = TextEditingController();
  final _interestsController = TextEditingController();

  String _initialDescription = '';
  String _initialInterests = '';
  bool _hasChanges = false;
  bool _isInitialized = false; 

  File? _pickedImage;
  bool _isLoading = false;

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


  Future<void> _showExitDialog() async {
    final shouldPop = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Cambios sin Guardar'),
        content: const Text('¿Estás seguro de que quieres salir sin guardar los datos?'),
        actions: [
          TextButton(
            child: const Text('Regresar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Salir'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

        if (shouldPop ?? false) {
      if(mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
      _checkForChanges();
    }
  }

  // ================== ACTUALIZAR IMAGEN ==================
  Future<void> _uploadImage() async {
    if (_pickedImage == null) return;

    setState(() => _isLoading = true);

    final token = ref.read(authTokenProvider);
    final userId = ref.read(userIdProvider);
    final apiUrl = ref.watch(moodleApiUrlProvider);

    if (token == null || userId == null) return;

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

    try {
      // Subir imagen al draft
      final response = await http.post(
        Uri.parse('$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      final responseData = json.decode(response.body);
      if (responseData.containsKey('exception')) {
        throw Exception('Error subiendo imagen: ${responseData['message']}');
      }

      final draftItemId = responseData['itemid'];

      // Actualizar la imagen del usuario
      final updateResponse = await http.post(
        Uri.parse('$apiUrl?wsfunction=core_user_update_picture&wstoken=$token&moodlewsrestformat=json'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'draftitemid': draftItemId.toString(),
          'userid': userId.toString(),
        },
      );
    //  ref.invalidate(userProfileProvider);
      
      final updateData = json.decode(updateResponse.body);
      if (updateData['success'] == true) {
        ref.invalidate(userProfileProvider);
       // setState(() {
       //   _initialDescription = _descriptionController.text;
       //   _initialInterests = _interestsController.text;
       // });
      setState(() {
        _hasChanges = false;
        _pickedImage = null;
        _initialDescription = _descriptionController.text;
        _initialInterests = _interestsController.text;
      });


       // setState(() {
       // _hasChanges = false;
       // });
       
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada con éxito'), backgroundColor: Colors.green),
        );
        setState(() => _pickedImage = null); // Limpiar imagen seleccionada
      } else {
        throw Exception('Error al actualizar imagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imagen: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================== ACTUALIZAR PERFIL (DESCRIPCIÓN/INTERESES) ==================
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    final token = ref.read(authTokenProvider);
    final userId = ref.read(userIdProvider);
    final apiUrl = ref.watch(moodleApiUrlProvider);

    if (token == null || userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?wsfunction=core_user_update_users&wstoken=$token&moodlewsrestformat=json'),
        body: {
          'users[0][id]': userId.toString(),
          'users[0][description]': _descriptionController.text,
          'users[0][interests]': _interestsController.text,
        },
      );
 //     ref.invalidate(userProfileProvider); 
      final responseData = json.decode(response.body);
      if (responseData is List && responseData.isNotEmpty && responseData[0]['exception'] != null) {
        throw Exception('Error al actualizar perfil: ${responseData[0]['message']}');
      }

     ref.invalidate(userProfileProvider);
     // setState(() {
     //   _initialDescription = _descriptionController.text;
     //   _initialInterests = _interestsController.text;
     // });
     // setState(() {
     // _hasChanges = false;
     // });
           setState(() {
        _hasChanges = false;
        _pickedImage = null;
        _initialDescription = _descriptionController.text;
        _initialInterests = _interestsController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green),
      );


    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando perfil: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(userProfileProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('EDITAR PERFIL'), centerTitle: true),
        body: asyncProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error al cargar perfil: $err')),
          data: (user) {
            if (!_isInitialized) {
              _initialDescription = (user['description'] ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();
              _initialInterests = user['interests'] ?? '';
              _descriptionController.text = _initialDescription;
              _interestsController.text = _initialInterests;
              _isInitialized = true;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _descriptionController,
                maxLines: null ,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done, 
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSubmitted: (_) {
                  FocusScope.of(context).unfocus(); // 👈 cierra el teclado
                },),
                const SizedBox(height: 24),
                const Text('Intereses', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _interestsController, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 24),
                const Text('Imagen de Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                      image: _pickedImage != null
                          ? DecorationImage(image: FileImage(_pickedImage!), fit: BoxFit.cover)
                          : (user['profileimageurl'] != null && user['profileimageurl'].isNotEmpty)
                              ? DecorationImage(image: NetworkImage(user['profileimageurl']), fit: BoxFit.cover)
                              : null,
                    ),
                    child: (_pickedImage == null && (user['profileimageurl'] == null || user['profileimageurl'].isEmpty))
                        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey), SizedBox(height: 8), Text('Toca para cambiar de imagen')]))
                        : null,
                  ),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: () async {
                          if (_pickedImage != null) {
                            await _uploadImage();
                          }
                          await _updateProfile();
                        },
                        child: const Text('Guardar Cambios'),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}








/*
class EditarPerfil extends ConsumerStatefulWidget {
  const EditarPerfil({super.key});

  @override
  ConsumerState<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends ConsumerState<EditarPerfil> {
  // Controladores para los campos de texto
  final _descriptionController = TextEditingController();
  final _interestsController = TextEditingController();

  String _initialDescription = '';
  String _initialInterests = '';

  bool _hasChanges = false; // Para saber si hay cambios
  // Variable para guardar la imagen seleccionada
  File? _pickedImage;
  bool _isLoading = false;

  // Función para seleccionar una imagen de la galería
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }
  @override
  void initState() {
    super.initState();
    // Añade 'listeners' para detectar cuando el usuario escribe algo
    _descriptionController.addListener(_checkForChanges);
    _interestsController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanged = _descriptionController.text != _initialDescription || 
                       _interestsController.text != _initialInterests;
    if (hasChanged != _hasChanges) {
      setState(() {
        _hasChanges = hasChanged;
      });
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

  Future<void> _showExitDialog() async {
    final shouldPop = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Cambios sin Guardar'),
        content: const Text('¿Estás seguro de que quieres salir sin guardar los datos?'),
        actions: [
          TextButton(
            child: const Text('Regresar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Salir'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

        if (shouldPop ?? false) {
      if(mounted) Navigator.of(context).pop();
    }
  }
  // Función para guardar los cambios en Moodle
  // En tu archivo editar_perfil.dart
  // Función que muestra el diálogo de confirmación

  
Future<void> _saveProfile() async {
  setState(() { _isLoading = true; });

  final token = ref.read(authTokenProvider);
  final userId = ref.read(userIdProvider);

  if (token == null || userId == null) {
    setState(() { _isLoading = false; });
    return;
  }

  const String apiUrl = 'http://192.168.1.45/tesismovil/webservice/rest/server.php';
   //final moodleApiUrl = ref.watch(moodleApiUrlProvider);
  try {
    await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'core_user_update_users',
        'moodlewsrestformat': 'json',
        'users[0][id]': userId.toString(),
        'users[0][description]': _descriptionController.text,
        'users[0][interests]': _interestsController.text,
      },
    );

    // --- PASO 2: Subir y asignar la imagen (si se seleccionó una nueva) ---
    if (_pickedImage != null) {
      
        final uploadUrl = '$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json';
  
      var uploadRequest = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields.addAll({
            'component': 'user',
            'filearea': 'draft',
            'itemid': '0',
            'filepath': '/',
            'filename': _pickedImage!.path.split('/').last,
        })
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          _pickedImage!.path,
          filename: _pickedImage!.path.split('/').last, 
        ));
print('--- CAMPOS DEL FORMULARIO ---');
print(uploadRequest.fields);
print('--- ARCHIVO ENVIADO ---');
print(_pickedImage!.path);
    //  var uploadRequest = http.MultipartRequest(...);
      var uploadResponse = await uploadRequest.send();
       var responseBody = await uploadResponse.stream.bytesToString();
       //final uploadData = json.decode(responseBody);
       

          // --- AÑADE ESTE PRINT PARA DEPURAR ---
      print('--- RESPUESTA DE SUBIDA DE ARCHIVO ---');
      print(responseBody);
      print('------------------------------------');
  // ----------------------------------------
      
      if (uploadResponse.statusCode == 200) {
        // 1. La respuesta es un Mapa, no una Lista.
        // 1. La respuesta es un Objeto (Mapa), no una Lista.
         final Map<String, dynamic> responseData = json.decode(responseBody);

    // 2. Comprobamos si la respuesta es en realidad un error de Moodle.
    if (responseData.containsKey('exception')) {
      throw Exception('Error de Moodle: ${responseData['message']}');
    }

    // --- LA CORRECCIÓN FINAL ESTÁ AQUÍ ---
    // 3. Accedemos al itemid DIRECTAMENTE desde el mapa, sin [0].
    final int draftItemId = responseData['itemid'];

    // 4. Asignamos la imagen (esta parte ya estaba bien).
    await http.post(
      Uri.parse(apiUrl),
      body: {
        'wstoken': token,
        'wsfunction': 'core_user_update_picture',
        'moodlewsrestformat': 'json',
        'draftitemid': draftItemId.toString(),
        'userid': userId.toString(),
      },
    );

  } else{
         throw Exception('Error al subir la imagen: ${responseBody}');
      }
    }

    // Invalida el provider para que la pantalla de perfil se actualice
    ref.invalidate(userProfileProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green)
      );
      Navigator.of(context).pop();
    }

  } catch (e) {
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red)
      );
    }
  } finally {
     if(mounted) {
      setState(() { _isLoading = false; });
    }
  }
}

  @override
  Widget build(BuildContext context) {
   // final colors = Theme.of(context).colorScheme;
    // Escucha al provider del perfil para obtener los datos iniciales
    final asyncProfile = ref.watch(userProfileProvider);

    return PopScope(
       canPop: !_hasChanges, // Bloquea el botón de atrás si hay cambios
       onPopInvokedWithResult:(bool didPop, dynamic result) {
       if (didPop) return;
       _showExitDialog();
     },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('EDITAR PERFIL'),
          centerTitle: true,
        ),
        // Muestra la UI según el estado del provider
        body: asyncProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error al cargar perfil: $err')),
          data: (user) {
            // Asigna los datos iniciales a los controladores solo una vez
           // _descriptionController.text = user['description'] ?? '';
             // Extraemos la descripción con HTML
            final String rawDescription = user['description'] ?? '';
            if (!_hasChanges) {
              _initialDescription = rawDescription.replaceAll(RegExp(r'<[^>]*>'), '').trim(); 
              _initialInterests = user['interests'] ?? '';
              _descriptionController.text = _initialDescription;
              _interestsController.text = _initialInterests;
            }      
            // Limpiamos las etiquetas HTML y asignamos el texto limpio al controlador
        //    _descriptionController.text = rawDescription.replaceAll(RegExp(r'<[^>]*>'), '').trim(); 
        //    _interestsController.text = user['interests'] ?? '';
      
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                
                const Text('Intereses (separados por coma)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _interestsController,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
      
               const Text('Imagen de Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                      // Muestra la imagen seleccionada o la imagen actual del usuario
                      image: _pickedImage != null
                          ? DecorationImage(image: FileImage(_pickedImage!), fit: BoxFit.cover)
                          : (user['profileimageurl'] != null && user['profileimageurl'].isNotEmpty)
                              ? DecorationImage(image: NetworkImage(user['profileimageurl']), fit: BoxFit.cover)
                              : null,
                    ),
                    // Muestra el ícono de subir solo si no hay imagen
                    child: (_pickedImage == null && (user['profileimageurl'] == null || user['profileimageurl'].isEmpty))
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Toca para cambiar de imagen'),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 32),
                
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _saveProfile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      child: const Text('Guardar Cambios'),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
 }*/