import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/assign_provider.dart';
import 'package:go_router/go_router.dart';
 // Ajusta la ruta

class CrearTareaScreen extends ConsumerStatefulWidget {
  final int courseId;
  final List sections;

  const CrearTareaScreen({
    super.key, 
    required this.courseId, 
    required this.sections
  });

  @override
  ConsumerState<CrearTareaScreen> createState() => _CrearTareaScreenState();
}

class _CrearTareaScreenState extends ConsumerState<CrearTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedSectionNum;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Nueva Tarea'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. Selector de Sección
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Sección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_open),
                ),
                value: _selectedSectionNum,
                items: widget.sections.map((sec) {
                  return DropdownMenuItem<int>(
                    value: int.parse(sec['section'].toString()),
                    child: Text(sec['name'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSectionNum = val),
                validator: (val) => val == null ? 'Por favor elige una sección' : null,
              ),


              const SizedBox(height: 20),

              // 2. Campo de Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la Tarea',
                  hintText: 'Ej: Informe de Python Inicial',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 20),

              // 3. Campo de Instrucciones
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Instrucciones/Descripción',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // 4. Botón de Creación
              ElevatedButton.icon(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.save),
                label: const Text('CREAR TAREA EN MOODLE', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Mostramos indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ref.read(assignActionsProvider).crearTareaMoodle(
        courseId: widget.courseId,
        sectionNumber: _selectedSectionNum!,
        nombre: _titleController.text,
      );

      if (context.mounted) {
        Navigator.pop(context); // Quita el loading
        if (success) {
          context.pop(); // Regresa a la lista de materias
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea creada exitosamente en el curso')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear el módulo en el servidor')),
          );
        }
      }
    }
  }
}