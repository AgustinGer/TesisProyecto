import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/submissions_provider.dart';
import 'package:go_router/go_router.dart';

class ListaEstudiantesScreen extends ConsumerWidget {
  final int courseId;
  const ListaEstudiantesScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(courseStudentsProvider(courseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Estudiantes')),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No hay estudiantes'));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (_, index) {
              final s = students[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: s['profileimageurl'] != null &&
                          s['profileimageurl'].toString().isNotEmpty
                      ? NetworkImage(s['profileimageurl'])
                      : null,
                  child: s['profileimageurl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(s['fullname']),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // 👉 Aquí vas a la pantalla de notas del estudiante
                  context.push(
                    '/mis-notas/$courseId/${s['id']}',
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
