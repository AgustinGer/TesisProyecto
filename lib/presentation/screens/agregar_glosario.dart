import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/glosario_actions.dart';
import 'package:http/http.dart' as http;
// Ajusta estos imports a tu estructura real
import 'package:flutter_tesis/provider/auth_provider.dart';


class AgregarGlosarioScreen extends ConsumerStatefulWidget {
  final int glossaryId;

  const AgregarGlosarioScreen({super.key, required this.glossaryId});

  @override
  ConsumerState<AgregarGlosarioScreen> createState() => _AgregarGlosarioScreenState();
}

class _AgregarGlosarioScreenState extends ConsumerState<AgregarGlosarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _definitionController = TextEditingController();
  
  // Variables para archivos (Reutilizando tu lógica)
  List<File> _pickedFiles = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _conceptController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  // --- 1. LÓGICA DE SELECCIÓN DE ARCHIVOS (Tu código reutilizado) ---
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    List<File> newFiles = result.paths.where((path) => path != null).map((path) => File(path!)).toList();

    setState(() {
      _pickedFiles.addAll(newFiles);
    });
  }

  // --- 2. LÓGICA DE SUBIDA Y GUARDADO ---
  Future<void> _guardarEntrada() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);
    
    // Providers
    final token = ref.read(authTokenProvider);
    final userId = ref.read(userIdProvider); // Asegúrate de tener este provider
    final apiUrl = ref.read(moodleApiUrlProvider);

    int? draftItemId;

    try {
      // A) SI HAY ARCHIVOS, LOS SUBIMOS PRIMERO A DRAFT
      if (_pickedFiles.isNotEmpty) {
        print('--- Subiendo imágenes al Draft ---');
        
        for (var file in _pickedFiles) {
          final filename = file.path.split('/').last;
          final bytes = await file.readAsBytes();
          final base64File = base64Encode(bytes);

          final response = await http.post(
            Uri.parse('$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json'),
            body: {
              'component': 'user',
              'filearea': 'draft',
              'itemid': (draftItemId ?? 0).toString(), // 0 para el primero, luego el ID que devuelve Moodle
              'filepath': '/',
              'filename': filename,
              'filecontent': base64File,
              'contextlevel': 'user',
              'instanceid': userId.toString(), 
            },
          );

          final uploadData = json.decode(response.body);
          if (uploadData.containsKey('itemid')) {
             draftItemId = uploadData['itemid']; // Guardamos el ID para usarlo al crear la entrada
             print('✅ Imagen subida. DraftID: $draftItemId');
          } else {
             throw Exception('Error subiendo imagen: ${uploadData['message']}');
          }
        }
      }

      // B) CREAR LA ENTRADA EN EL GLOSARIO
      final success = await ref.read(glossaryActionsProvider).agregarEntrada(
        glossaryId: widget.glossaryId,
        concepto: _conceptController.text,
        definicion: _definitionController.text,
        attachmentId: draftItemId, // Pasamos el ID de las fotos subidas
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Entrada agregada correctamente!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Volver y recargar
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar en Moodle'), backgroundColor: Colors.red),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Palabra'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CAMPO CONCEPTO ---
              const Text('Concepto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _conceptController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Algoritmo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.abc),
                ),
                validator: (v) => v!.isEmpty ? 'Escribe la palabra' : null,
              ),
              const SizedBox(height: 20),

              // --- CAMPO DEFINICIÓN ---
              const Text('Definición', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _definitionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Escribe el significado detallado...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Escribe la definición' : null,
              ),
              const SizedBox(height: 20),

              // --- ZONA DE IMÁGENES (Estilo ActividadesScreen) ---
              const Text('Imágenes / Adjuntos (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              GestureDetector(
                onTap: _isUploading ? null : _pickFiles,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _pickedFiles.isEmpty
                    ? const Column(
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.indigo),
                          Text('Toca para agregar imágenes'),
                        ],
                      )
                    : Column(
                        children: [
                          ..._pickedFiles.map((file) => ListTile(
                            leading: const Icon(Icons.image, color: Colors.indigo),
                            title: Text(file.path.split('/').last),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() => _pickedFiles.remove(file)),
                            ),
                          )),
                          const Divider(),
                          const Text('Agregar más...', style: TextStyle(color: Colors.indigo)),
                        ],
                      ),
                ),
              ),

              const SizedBox(height: 30),

              // --- BOTÓN ENVIAR ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isUploading ? null : _guardarEntrada,
                  icon: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.save),
                  label: Text(_isUploading ? 'GUARDANDO...' : 'GUARDAR ENTRADA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}