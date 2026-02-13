import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
 // Asegúrate de importar tu provider de URL


/*
class H5PScreen extends ConsumerWidget {
  final int moduleId; // El ID del módulo (cmid)
  final String title;

  const H5PScreen({
    super.key,
    required this.moduleId,
    required this.title,
  });

  // Función para abrir en el navegador
  Future<void> _abrirEnNavegador(BuildContext context, String apiUrl) async {
    // 1. Limpiamos la URL de la API para obtener la base de Moodle
    // Ejemplo: de "https://moodle.com/webservice/rest/server.php" a "https://moodle.com"
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');

    // 2. Construimos la URL de la actividad H5P
    // Nota: Si usas Moodle moderno es 'mod/h5pactivity', si es antiguo es 'mod/hvp'
    final url = '$baseUrl/mod/h5pactivity/view.php?id=$moduleId';

    final uri = Uri.parse(url);

    try {
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Abre Chrome/Safari
      )) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos la URL base desde el provider
    final apiUrl = ref.watch(moodleApiUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividad H5P'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono grande
            const Icon(Icons.touch_app_rounded, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            
            // Título de la actividad
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            const Text(
              "Esta es una actividad interactiva. Para una mejor experiencia, se abrirá en tu navegador.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Botón de Acción
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
                label: const Text("IR A LA ACTIVIDAD WEB", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _abrirEnNavegador(context, apiUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/

class H5PScreen extends ConsumerWidget {
  final int moduleId; 
  final String title;
  final String modName; // <--- NUEVO: Recibimos el tipo ('h5pactivity' o 'hvp')

  const H5PScreen({
    super.key,
    required this.moduleId,
    required this.title,
    required this.modName, // <--- Lo pedimos en el constructor
  });

  Future<void> _abrirEnNavegador(BuildContext context, String apiUrl) async {
    final baseUrl = apiUrl.replaceAll('/webservice/rest/server.php', '');
    
    // LÓGICA DINÁMICA DE URL
    String path = '';
    
    if (modName == 'hvp') {
      // Es el icono NEGRO (Plugin antiguo)
      path = '/mod/hvp/view.php';
    } else {
      // Es el icono AZUL (Moodle Nativo - h5pactivity)
      path = '/mod/h5pactivity/view.php';
    }

    final url = '$baseUrl$path?id=$moduleId';
    final uri = Uri.parse(url);

    try {
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiUrl = ref.watch(moodleApiUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(modName == 'hvp' ? 'Contenido Interactivo' : 'Actividad H5P'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono dinámico según el tipo
            Icon(
              Icons.touch_app_rounded, 
              size: 80, 
              color: modName == 'hvp' ? Colors.black87 : Colors.indigo
            ),
            const SizedBox(height: 20),
            
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            const Text(
              "Esta actividad interactiva se abrirá en tu navegador para asegurar su correcto funcionamiento.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: modName == 'hvp' ? Colors.black87 : Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_browser),
                label: const Text("ABRIR ACTIVIDAD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _abrirEnNavegador(context, apiUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}