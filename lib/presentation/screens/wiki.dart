import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';


class WikiScreen extends ConsumerWidget {
  final int moduleId; // cmid
  final String title;

  const WikiScreen({
    super.key,
    required this.moduleId,
    required this.title,
  });

  Future<void> _abrirEnNavegador(BuildContext context, String apiUrl) async {
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    
    // URL estándar de Moodle para Wiki
    final url = '$baseUrl/mod/wiki/view.php?id=$moduleId';
    final uri = Uri.parse(url);

    try {
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('No se pudo abrir la Wiki');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiUrl = ref.watch(moodleApiUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wiki Colaborativa'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de documento/edición
            const Icon(Icons.edit_document, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            const Text(
              "La Wiki requiere funciones de edición de texto enriquecido y gestión de versiones. Se abrirá en tu navegador para permitirte editar correctamente.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_browser),
                label: const Text("IR A LA WIKI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _abrirEnNavegador(context, apiUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}