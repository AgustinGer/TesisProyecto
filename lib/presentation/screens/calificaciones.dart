import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/notas_provider.dart';

class MisNotasScreen extends ConsumerWidget {
  final int courseId;
  final int? userId; //opcional
  const MisNotasScreen({super.key, required this.courseId, this.userId,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // USAMOS EL NUEVO PROVIDER
   // final gradesAsync = ref.watch(courseGradesProvider(courseId));
    final gradesAsync = ref.watch(courseGradesProvider((courseId: courseId, userId: userId)),);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Calificaciones')),
      body: gradesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (grades) {
          if (grades.isEmpty) return const Center(child: Text('No hay notas disponibles.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final item = grades[index];
              
              // LOGICA MEJORADA PARA EL NOMBRE
              String displayName = item.itemname;
              
              // Si Moodle dice que este item es el total del curso o categoría
              if (item.isCategory || displayName == 'Elemento de calificación') {
                displayName = 'Total del Curso';
              }
              // Si es tipo categoría (total), lo resaltamos
              final isTotal = item.isCategory || item.itemname.toLowerCase().contains('total');

              return Card(
                elevation: isTotal ? 4 : 1,
                color: isTotal ? Colors.indigo.shade50 : Colors.white,
                child: ListTile(
                  title: Text(
                   // item.itemname,
                    displayName,
                    style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
                  ),
                  subtitle: Text('Rango: ${item.rangeformatted}'),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.gradeformatted == '-' ? Colors.grey[300] : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.gradeformatted,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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