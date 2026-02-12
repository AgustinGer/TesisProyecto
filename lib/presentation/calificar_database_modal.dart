import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:http/http.dart' as http;


class CalificarDataBaseModal extends ConsumerStatefulWidget {
  //final int contextId;    // El Context ID del módulo (cmid context)
  final int moduleId;
  final int entryId;      // El ID de la entrada (recordid)
  final int ratedUserId;  // El ID del alumno a calificar
  final String studentName; 
  final int scaleId;      // La nota máxima

  const CalificarDataBaseModal({
    super.key,
    //required this.contextId,
    required this.moduleId,
    required this.entryId,
    required this.ratedUserId,
    required this.studentName,
    required this.scaleId,
  });

  @override
  ConsumerState<CalificarDataBaseModal> createState() => _CalificarDataBaseModalState();
}

class _CalificarDataBaseModalState extends ConsumerState<CalificarDataBaseModal> {
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _enviarCalificacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final token = ref.read(authTokenProvider);
    final apiUrl = ref.read(moodleApiUrlProvider);
    
    // Moodle espera la calificación como int (si es escala numérica)
    final int ratingValue = int.tryParse(_gradeController.text) ?? 0;

    try {
      print('--- Enviando Calificación Base de Datos ---');
     // print('ContextID: ${widget.contextId}, EntryID: ${widget.entryId}, Rating: $ratingValue');

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'wstoken': token,
          'wsfunction': 'core_rating_add_rating', // Función universal de calificación
          'moodlewsrestformat': 'json',
          
          'contextlevel': 'module',              // <--- SIEMPRE 'module'
          'instanceid': widget.moduleId.toString(),
          'component': 'mod_data',               // <--- CRÍTICO: Debe ser mod_data
          'ratingarea': 'entry',                 // <--- CRÍTICO: Debe ser entry
          'itemid': widget.entryId.toString(),   // ID de la entrada
          'scaleid': widget.scaleId.toString(),  
          'rating': ratingValue.toString(),      
          'rateduserid': widget.ratedUserId.toString(), 
          'aggregation': '1',

        },
      );

      final data = json.decode(response.body);
      print('Respuesta Moodle Rating: $data');

      if (mounted) {
        setState(() => _isSubmitting = false);

        // Verificamos éxito: Moodle suele devolver "success": true o el objeto rating
        if (data is Map && (data['success'] == true || data.containsKey('rating'))) {
          Navigator.pop(context); // Cerramos el modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Calificación guardada con éxito!'), backgroundColor: Colors.green),
          );
        } else if (data is Map && data.containsKey('exception')) {
          // Error de Moodle
          String errorMsg = data['message'] ?? 'Error desconocido';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error Moodle: $errorMsg'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Error red: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si scaleId es negativo, es una escala personalizada, usamos 100 por defecto para validar visualmente
    final int maxGrade = widget.scaleId > 0 ? widget.scaleId : 100;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Calificar Entrada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
            if (widget.studentName.isNotEmpty)
              Text('Estudiante: ${widget.studentName}', style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 20),

            TextFormField(
              controller: _gradeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Calificación (0 - $maxGrade)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.grade),
                suffixText: '/ $maxGrade',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa una nota';
                final n = int.tryParse(value);
                if (n == null) return 'Debe ser un número entero';
                if (maxGrade > 0 && (n < 0 || n > maxGrade)) return 'La nota debe estar entre 0 y $maxGrade';
                return null;
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: _isSubmitting ? null : _enviarCalificacion,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR CALIFICACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}