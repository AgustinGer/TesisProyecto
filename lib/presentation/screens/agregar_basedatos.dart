import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/database_fiel_model.dart';
import 'package:flutter_tesis/provider/database_actions_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tesis/provider/auth_provider.dart'; 

/*
class AgregarBaseDatosScreen extends ConsumerStatefulWidget {
  final int databaseId;

  const AgregarBaseDatosScreen({super.key, required this.databaseId});

  @override
  ConsumerState<AgregarBaseDatosScreen> createState() => _AgregarBaseDatosScreenState();
}

class _AgregarBaseDatosScreenState extends ConsumerState<AgregarBaseDatosScreen> {
  // Mapa para guardar lo que escribe el usuario: { fieldId : "valor escrito" }
  final Map<int, String> _formData = {};
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save(); // Guarda los valores de los TextFields en el mapa

    setState(() => _isUploading = true);

    final success = await ref.read(databaseActionsProvider).agregarEntrada(
      databaseId: widget.databaseId,
      values: _formData,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado con éxito'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Regresa true para recargar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red));
      }
    }
  }

  // --- FABRICA DE WIDGETS SEGÚN TIPO DE CAMPO ---
  Widget _buildFieldWidget(DatabaseField field) {
    // Si es texto corto, número, url o área de texto
    if (['text', 'textarea', 'number', 'url', 'latlong'].contains(field.type)) {
      final isNumber = field.type == 'number';
      final isArea = field.type == 'textarea';

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: field.name + (field.required ? ' *' : ''),
            helperText: field.description.isNotEmpty ? field.description : null,
            border: const OutlineInputBorder(),
          ),
          keyboardType: isNumber ? TextInputType.number : (isArea ? TextInputType.multiline : TextInputType.text),
          maxLines: isArea ? 4 : 1,
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
          onSaved: (newValue) {
            if (newValue != null) {
              _formData[field.id] = newValue;
            }
          },
        ),
      );
    } 
    
    // Si es un tipo complejo que aún no soportamos (Imagen, Archivo, Checkbox)
    else {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text('El campo "${field.name}" (${field.type}) no es compatible con la App móvil aún.', style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(databaseFieldsProvider(widget.databaseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Entrada'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (fields) {
          if (fields.isEmpty) return const Center(child: Text('Esta base de datos no tiene campos definidos.'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // DIBUJAMOS LOS CAMPOS DINÁMICAMENTE
                  ...fields.map((field) => _buildFieldWidget(field)),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: _isUploading ? null : _guardar,
                      child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('GUARDAR ENTRADA'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}*/




class AgregarBaseDatosScreen extends ConsumerStatefulWidget {
  final int databaseId;

  const AgregarBaseDatosScreen({super.key, required this.databaseId});

  @override
  ConsumerState<AgregarBaseDatosScreen> createState() => _AgregarBaseDatosScreenState();
}

class _AgregarBaseDatosScreenState extends ConsumerState<AgregarBaseDatosScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  // --- ESTADOS PARA LOS DATOS ---

  // 1. Texto simple (Text, Textarea, Number, Url) y selecciones únicas (Radio, Menu)
  // Se guardan directamente al dar "Guardar" gracias al onSaved de los widgets.
  final Map<int, String> _formData = {};

  // 2. Archivos y Fotos: Mapa de FieldID -> Archivo seleccionado
  final Map<int, File?> _selectedFiles = {};

  // 3. Checkboxes (Selección múltiple): Mapa de FieldID -> Set de opciones marcadas
  final Map<int, Set<String>> _checkboxStates = {};


  // --- LÓGICA DE ARCHIVOS (Similar a Glosario) ---

  Future<void> _pickFile(int fieldId, bool isImage) async {
    final result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFiles[fieldId] = File(result.files.single.path!);
      });
    }
  }

  // Función auxiliar para subir un solo archivo a Moodle Draft
  Future<int?> _uploadFileToDraft(File file) async {
    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);
    final userId = ref.read(userIdProvider);

print('\n--- DEBUG: SUBIENDO ARCHIVO A DRAFT ---');
    print('Usuario ID: $userId');
    print('Archivo: ${file.path}');

    if (userId == null) {
      print('❌ Error: User ID es null');
      return null;
    }
    
    // Usamos un instanceid negativo temporal como sugiere la doc de Moodle para drafts nuevos
    
    //const draftInstanceId = -1; 

    try {
        final filename = file.path.split('/').last;
        final bytes = await file.readAsBytes();
        final base64File = base64Encode(bytes);

        print('Enviando petición a core_files_upload...');

        final response = await http.post(
          Uri.parse('$apiUrl?wsfunction=core_files_upload&wstoken=$token&moodlewsrestformat=json'),
          body: {
            'component': 'user',
            'filearea': 'draft',
            'itemid': '0', // 0 para el primer archivo de un área draft
            'filepath': '/',
            'filename': filename,
            'filecontent': base64File,
            'contextlevel': 'user',
            'instanceid': userId.toString(), 
          },
        );


print('Respuesta Draft Body: ${response.body}');


        final data = json.decode(response.body);
        if (data is Map && data.containsKey('itemid')) {
           final draftId = data['itemid'];
           print('✅ Archivo subido al Draft. Draft ID: $draftId');
           return draftId;
        }
        print('❌ Error en respuesta Draft: $data');
        return null;
    } catch (e) {
      print('❌ Excepción subiendo archivo: $e');
      return null;
    }
  }


  // --- LÓGICA PRINCIPAL DE GUARDADO ---

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa los campos obligatorios.')));
      return;
    }
    
 
    // 1. Guarda los campos de texto/radio/menu en _formData
    _formKey.currentState!.save(); 

    setState(() => _isUploading = true);

    try {
      // 2. PROCESAR CHECKBOXES (Convertir Sets a strings separados por coma)
      _checkboxStates.forEach((fieldId, selectedOptions) {
        if (selectedOptions.isNotEmpty) {
          // Moodle suele aceptar múltiples valores separados por coma para checkboxes
          _formData[fieldId] = selectedOptions.join(',');
        }
      });

      // 3. PROCESAR Y SUBIR ARCHIVOS
      // Iteramos por los archivos seleccionados y los subimos uno por uno
      for (var entry in _selectedFiles.entries) {
        final fieldId = entry.key;
        final file = entry.value;
        if (file != null) {
          // Subimos y obtenemos el Draft ID
          final draftItemId = await _uploadFileToDraft(file);
          if (draftItemId != null) {
             // Guardamos el Draft ID como el valor del campo
            _formData[fieldId] = draftItemId.toString();
          } else {
             throw Exception('Falló la subida de un archivo. Intenta de nuevo.');
          }
        }
      }

      // 4. Validar que los campos obligatorios de archivo/checkbox tengan datos
      // (La validación estándar del Form no sirve bien para estos)
      final fields = ref.read(databaseFieldsProvider(widget.databaseId)).valueOrNull ?? [];
      for (var field in fields) {
        if (field.required && !_formData.containsKey(field.id)) {
           throw Exception('El campo "${field.name}" es obligatorio.');
        }
      }


      final fieldsList = ref.read(databaseFieldsProvider(widget.databaseId)).value ?? [];

      // 5. ENVIAR EL FORMULARIO FINAL
      final success = await ref.read(databaseActionsProvider).agregarEntrada(
        databaseId: widget.databaseId,
        values: _formData,
        fields: fieldsList, // <--- PASAMOS LA LISTA AQUÍ
      );
      // 5. ENVIAR EL FORMULARIO FINAL
      /*final success = await ref.read(databaseActionsProvider).agregarEntrada(
        databaseId: widget.databaseId,
        values: _formData,
      );*/

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado con éxito'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar la entrada en Moodle'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
      }
    }
  }


  // --- BUILDERS DE WIDGETS ESPECÍFICOS ---

  // Builder para Archivos e Imágenes
  Widget _buildFilePickerWidget(DatabaseField field) {
    final isImage = field.type == 'picture';
    final selectedFile = _selectedFiles[field.type == 'picture' ? field.id : field.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.name + (field.required ? ' *' : ''), style: const TextStyle(fontWeight: FontWeight.bold)),
        if (field.description.isNotEmpty) Text(field.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        
        GestureDetector(
          onTap: _isUploading ? null : () => _pickFile(field.id, isImage),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(isImage ? Icons.image : Icons.insert_drive_file, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedFile != null ? selectedFile.path.split('/').last : 'Toca para seleccionar ${isImage ? 'imagen' : 'archivo'}',
                    style: TextStyle(color: selectedFile != null ? Colors.black : Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedFiles.remove(field.id)),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Builder para Radio Buttons (Selección única)
  Widget _buildRadioWidget(DatabaseField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.name + (field.required ? ' *' : ''), style: const TextStyle(fontWeight: FontWeight.bold)),
        if (field.description.isNotEmpty) Text(field.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        
        // Usamos un FormField para poder validarlo
        FormField<String>(
          validator: (value) {
            if (field.required && _formData[field.id] == null) return 'Debes seleccionar una opción.';
            return null;
          },
          onSaved: (value) {
            // El valor ya se guarda en el onChanged, no necesitamos hacer nada aquí
          },
          builder: (FormFieldState<String> state) {
            return Column(
              children: field.options.map((option) {
                return RadioListTile<String>(
                 // title: Text(option),
                  title: Text('"$option"'),
                  value: option,
                  groupValue: _formData[field.id],
                  onChanged: (val) {
                    setState(() {
                      _formData[field.id] = val!;
                      state.didChange(val); // Notifica al validador
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            );
          },
        ),
         if (_formKey.currentState?.validate() == false && field.required && _formData[field.id] == null)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text('Obligatorio', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
            )
      ],
    );
  }

  // Builder para Checkboxes (Selección múltiple)
  Widget _buildCheckboxWidget(DatabaseField field) {
    // Inicializamos el set si no existe
    _checkboxStates.putIfAbsent(field.id, () => {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.name + (field.required ? ' *' : ''), style: const TextStyle(fontWeight: FontWeight.bold)),
        if (field.description.isNotEmpty) Text(field.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

        ...field.options.map((option) {
          final isChecked = _checkboxStates[field.id]!.contains(option);
          return CheckboxListTile(
            title: Text(option),
            value: isChecked,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _checkboxStates[field.id]!.add(option);
                } else {
                  _checkboxStates[field.id]!.remove(option);
                }
              });
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      ],
    );
  }
  
  // Builder para Menú Desplegable (Dropdown)
  Widget _buildMenuWidget(DatabaseField field) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: field.name + (field.required ? ' *' : ''),
          helperText: field.description.isNotEmpty ? field.description : null,
          border: const OutlineInputBorder(),
        ),
        value: _formData[field.id], // Valor actual
        items: field.options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
           setState(() {
             if (newValue != null) _formData[field.id] = newValue;
           });
        },
        validator: (value) {
          if (field.required && (value == null || value.isEmpty)) {
            return 'Por favor selecciona una opción.';
          }
          return null;
        },
        onSaved: (newValue) {
           if (newValue != null) _formData[field.id] = newValue;
        },
      );
  }


  // --- SWITCH PRINCIPAL DE WIDGETS ---
  Widget _buildFieldWidget(DatabaseField field) {
    switch (field.type) {
      case 'text':
      case 'textarea':
      case 'number':
      case 'url':
      //case 'latlong': // Latlong suele ser texto simple
        final isNumber = field.type == 'number';
        final isArea = field.type == 'textarea';
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.name + (field.required ? ' *' : ''),
            helperText: field.description.isNotEmpty ? field.description : null,
            border: const OutlineInputBorder(),
          ),
          keyboardType: isNumber ? TextInputType.number : (isArea ? TextInputType.multiline : TextInputType.text),
          maxLines: isArea ? 4 : 1,
          validator: (value) {
            if (field.required && (value == null || value.isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
          onSaved: (newValue) {
            if (newValue != null && newValue.isNotEmpty) {
              _formData[field.id] = newValue;
            }
          },
        );

      case 'file':
      case 'picture':
        return _buildFilePickerWidget(field);

      case 'radiobutton':
        return _buildRadioWidget(field);

      case 'checkbox':
      case 'multicheckbox':
        return _buildCheckboxWidget(field);
        
      case 'menu':
        return _buildMenuWidget(field);

      default:
        // Tipos aún no soportados (Ej: date, latlong complejo)
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(child: Text('El campo "${field.name}" (${field.type}) no es compatible aún.', style: const TextStyle(fontSize: 12))),
            ],
          ),
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(databaseFieldsProvider(widget.databaseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Entrada'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error cargando formulario: $err'),
        )),
        data: (fields) {
          if (fields.isEmpty) return const Center(child: Text('No hay campos definidos.'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Renderizamos cada campo con un padding inferior
                  ...fields.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildFieldWidget(field),
                  )),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: _isUploading ? null : _guardar,
                      child: _isUploading 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 15),
                              Text("Subiendo datos...")
                            ],
                          )
                        : const Text('GUARDAR ENTRADA'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}