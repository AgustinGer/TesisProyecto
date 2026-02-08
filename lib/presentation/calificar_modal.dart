import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/rating_provider.dart';


class CalificarModal extends ConsumerStatefulWidget {
  final int contextId;
  final int entryId;
  final int ratedUserId;
  final String studentName;
  final int scaleId;

  const CalificarModal({
    super.key,
    required this.contextId,
    required this.entryId,
    required this.ratedUserId,
    required this.studentName,
    required this.scaleId,
  });

  @override
  ConsumerState<CalificarModal> createState() => _CalificarModalState();
}

class _CalificarModalState extends ConsumerState<CalificarModal> {
  final _gradeController = TextEditingController();
  bool _isLoading = false;

  void _enviarNota() async {
    final String text = _gradeController.text;
    if (text.isEmpty) return;

    final int? grade = int.tryParse(text);
    if (grade == null || grade < 0 || grade > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una nota válida (0-100)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(ratingActionsProvider).calificarEntrada(
      contextId: widget.contextId,
      entryId: widget.entryId,
      ratedUserId: widget.ratedUserId,
      rating: grade,
      scaleId: widget.scaleId,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.pop(context); // Cierra el modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calificación guardada'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar nota'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Esto hace que el modal suba cuando sale el teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calificar a: ${widget.studentName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          TextField(
            controller: _gradeController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nota (0-100)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.grade),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: _isLoading ? null : _enviarNota,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('GUARDAR CALIFICACIÓN'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}