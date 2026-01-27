import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/submissions_provider.dart';
import 'package:go_router/go_router.dart';


class EstudianteTareaScreen extends ConsumerWidget {
  final int courseId;
  final int assignId;

  const EstudianteTareaScreen({super.key, required this.courseId, required this.assignId});
// Dentro del build de EstudianteTareaScreen
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Observa el cambio aquí: (field: value, field: value)
  final studentsAsync = ref.watch(studentSubmissionsProvider(
    (courseId: courseId, assignId: assignId)
  ));

  return Scaffold(
    appBar: AppBar(title: const Text('Entregas de Estudiantes')),
    body: studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('No hay estudiantes enrolados.'));
        }
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final bool entregado = student['hasSubmitted'];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(student['profileimageurl']),
              ),
              title: Text(student['fullname']),
              subtitle: Text(
                entregado ? 'Entregado' : 'Pendiente',
                style: TextStyle(color: entregado ? Colors.green : Colors.red),
              ),
              trailing: Icon(
                entregado ? Icons.check_circle : Icons.error_outline,
                color: entregado ? Colors.green : Colors.grey,
              ),
              onTap: () {
                // Navegación a la pantalla de calificar
              print('Navegando a calificar: Curso $courseId, Tarea $assignId, Estudiante ${student['id']}');
                
                context.push(
                  '/calificar-tarea/$courseId/$assignId/${student['id']}',
                  extra: student['fullname']
                );
              },
            );
          },
        );
      },
    ),
  );
 }
}