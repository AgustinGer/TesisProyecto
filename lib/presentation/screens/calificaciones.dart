import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/shared/grade.dart';
import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:flutter_tesis/provider/notas_provider.dart';
import 'package:go_router/go_router.dart';


class MisNotasScreen extends ConsumerWidget {
  final int courseId;
  final int? userId; //opcional
  const MisNotasScreen({super.key, required this.courseId, this.userId,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // USAMOS EL NUEVO PROVIDER
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
                child: 
                
                ListTile(
                title: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.sectionName != null)
                      Text(
                        'Unidad: ${item.sectionName}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    Text('Rango: ${item.rangeformatted}'),
                  ],
                ),
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
                
                // onTap: () {
                onTap: isTotal
                    ? null
                    : () {
                        // 1️⃣ Validaciones
                        if (item.isCategory || item.iteminstance == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Este elemento no es una actividad')),
                          );
                          return;
                        }

                        if (item.itemmodule != 'assign') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Este tipo de actividad no está soportado')),
                          );
                          return;
                        }

                        final assignmentId = item.iteminstance!;

                        // 🔑 CLAVE: si userId != null → profesor viendo estudiante
                        if (userId != null) {
                          // 👨‍🏫 PROFESOR → calificar a ESTE estudiante
                          print(
                            'Navegando a calificar: Curso $courseId, '
                            'Tarea $assignmentId, Estudiante $userId',
                          );

                          context.push(
                            '/calificar-tarea/$courseId/$assignmentId/$userId',
                          );
                        } else {
                          // 👨‍🎓 ALUMNO → ver su entrega
                          print('Navegando como Estudiante a entrega de tarea: $assignmentId');

                          context.push(
                            '/actividades/$courseId/$assignmentId',
                          );
                        }
                      },
               ),
              );
            },
          );
        },
      ),
    );
  }
}


final gradesWithSectionProvider =
    FutureProvider.family<List<GradeItem>,
        ({int courseId, int? userId})>((ref, params) async {

  final grades =
      await ref.watch(courseGradesProvider(params).future);

  final modules =
      await ref.watch(courseContentProvider(params.courseId).future);

  // Creamos un mapa para búsqueda rápida
  final moduleMap = {
    for (final m in modules)
      '${m.modname}_${m.instance}': m.sectionName
  };

  for (final grade in grades) {
    if (grade.iteminstance != null) {
      final key = '${grade.itemmodule}_${grade.iteminstance}';
      grade.sectionName = moduleMap[key];
    }
  }

  return grades;
});
