import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/moddle_launcher.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';

class CrearTareaScreen extends ConsumerWidget {
  final int courseId;
  final List sections;

  const CrearTareaScreen({
    super.key,
    required this.courseId,
    required this.sections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Tarea')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Selecciona la sección donde se creará la tarea',
              style: TextStyle(fontSize: 16),
            ),
          ),

          ...sections.map((sec) {
            return ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(sec['name'] ?? 'Sección sin nombre'),
              onTap: () async {
                final sectionNumber = sec['section'];

                final moodleBaseUrl = ref.read(moodleBaseUrlProvider);

                final url =
                    '$moodleBaseUrl/course/modedit.php'
                    '?add=assign'
                    '&course=$courseId'
                    '&section=$sectionNumber';

                await launchMoodleUrl(url);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
