import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/grade_provider.dart';
import 'package:go_router/go_router.dart';


class PantallaCalificar extends ConsumerStatefulWidget {
  final int courseId;
  final int assignId;
  final int userId;
  final String studentName;

  const PantallaCalificar({
    super.key, 
    required this.courseId, 
    required this.assignId, 
    required this.userId, 
    required this.studentName
  });

  @override
  ConsumerState<PantallaCalificar> createState() => _PantallaCalificarState();
}

class _PantallaCalificarState extends ConsumerState<PantallaCalificar> {
  final _gradeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final submissionAsync = ref.watch(submissionDetailsProvider((assignId: widget.assignId, userId: widget.userId)));

    return Scaffold(
      appBar: AppBar(title: Text('Calificar: ${widget.studentName}')),
      body: submissionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final lastAttempt = data['lastattempt'] ?? {};
          final submission = lastAttempt['submission'] ?? {};
          final List plugins = submission['plugins'] ?? [];
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Estado', submission['status'] ?? 'Sin entrega', Colors.blue),
                const SizedBox(height: 20),
                const Text('Archivos / Respuesta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ...plugins.map((p) => ListTile(
                  title: Text(p['name']),
                  subtitle: const Text('Toca para ver el contenido'),
                  leading: const Icon(Icons.file_present),
                )),
                const Divider(height: 40),
                const Text('Asignar Calificación (0-100)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _gradeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej: 85'),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                    onPressed: () => _enviarCalificacion(context),
                    child: const Text('GUARDAR CALIFICACIÓN', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _enviarCalificacion(BuildContext context) async {
    final nota = double.tryParse(_gradeController.text);
    if (nota == null || nota < 0 || nota > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una nota válida entre 0 y 100')));
      return;
    }

    final success = await ref.read(gradeActionsProvider).guardarNota(
      assignId: widget.assignId,
      userId: widget.userId,
      nota: nota,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota guardada correctamente')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar la nota en Moodle')));
      }
    }
  }
}