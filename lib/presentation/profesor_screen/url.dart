import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:flutter_tesis/provider/url_provider.dart';
import 'package:go_router/go_router.dart';


class CrearUrlScreen extends ConsumerStatefulWidget {
  final int courseId;
  final List sections;

  const CrearUrlScreen({super.key, required this.courseId, required this.sections});

  @override
  ConsumerState<CrearUrlScreen> createState() => _CrearUrlScreenState();
}

class _CrearUrlScreenState extends ConsumerState<CrearUrlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  int? _selectedSectionNum;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Enlace Web')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Sección de destino'),
              items: widget.sections.map((sec) => DropdownMenuItem<int>(
                value: int.parse(sec['section'].toString()),
                child: Text(sec['name'] ?? 'Sin nombre'),
              )).toList(),
              onChanged: (val) => setState(() => _selectedSectionNum = val),
              validator: (val) => val == null ? 'Selecciona una sección' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título del enlace (Ej: Video Python)'),
              validator: (val) => val!.isEmpty ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'URL (http://...)'),
              validator: (val) => val!.isEmpty ? 'Ingresa la dirección web' : null,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _crearEnlace,
              child: const Text('GUARDAR ENLACE EN CURSO'),
            ),
          ],
        ),
      ),
    );
  }

  void _crearEnlace() async {
    if (_formKey.currentState!.validate()) {
      final resultado = await ref.read(urlActionsProvider).crearUrlMoodle(
        courseId: widget.courseId,
        sectionNumber: _selectedSectionNum!,
        titulo: _titleController.text,
        linkExterno: _linkController.text,
      );

    if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // Si resultado es true, muestra éxito. Si es false, muestra el error.
              content: Text(resultado 
                ? '¡Se creó el URL con éxito!' 
                : 'Error: Moodle no permite la creación rápida de URLs.'),
              backgroundColor: resultado ? Colors.green : Colors.red,
            ),
          );

          if (resultado) {
            ref.invalidate(courseContentProvider(widget.courseId));
            context.pop();
          }
        }
    }
  }
}