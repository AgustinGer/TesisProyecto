import 'package:flutter/material.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_tesis/provider/course_actions_provider.dart';
//import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// 1. Convertimos a un StatefulWidget

// 1. Convertimos a ConsumerStatefulWidget para usar ref

/*class VideoScreen extends ConsumerStatefulWidget {
  final String videoTitle;
  final String videoUrl;
  final bool isProfessor;
  final int moduleId;

  const VideoScreen({
    super.key,
    required this.videoTitle,
    required this.videoUrl,
    this.isProfessor = false,
    required this.moduleId,
  });

  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  late YoutubePlayerController _controller;
  late String currentTitle;
  late String currentUrl;

  @override
  void initState() {
    super.initState();
    currentTitle = widget.videoTitle;
    currentUrl = widget.videoUrl;

    final videoId = YoutubePlayer.convertUrlToId(currentUrl);
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        /*disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,*/
      ),
    );
  }

  void _mostrarDialogoEdicion() {
    final titleController = TextEditingController(text: currentTitle);
    final urlController = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL de YouTube')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
          onPressed: () async {
            final nuevoNombre = titleController.text;
            final nuevaUrl = urlController.text;

            // 1. Mostrar un pequeño diálogo de "Guardando..." o usar un flag de carga
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );

            // 2. Llamar al provider para guardar en Moodle
            final success = await ref.read(courseActionsProvider).editarUrlMoodle(
              moduleId: widget.moduleId,
              nuevoNombre: nuevoNombre,
              nuevaUrl: nuevaUrl,
            );

            // 3. Cerrar el indicador de carga
            if (context.mounted) Navigator.pop(context); 

            if (success) {
              setState(() {
                currentTitle = nuevoNombre;
                currentUrl = nuevaUrl;
                final newId = YoutubePlayer.convertUrlToId(currentUrl);
                if (newId != null) _controller.load(newId);
              });
              
              // 4. Notificar éxito
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Cambios guardados en Moodle!'), backgroundColor: Colors.green),
                );
                Navigator.pop(context); // Cierra el diálogo de edición
              }
              
              // 5. IMPORTANTE: Invalidar el provider del curso para que la pantalla anterior se actualice
              ref.invalidate(courseContentProvider); 
              
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al guardar en el servidor'), backgroundColor: Colors.red),
                );
              }
            }
          }, 
          child: const Text('Guardar'),
        ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos YoutubePlayerBuilder para que el plugin maneje mejor el estado
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.amber,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Videos'),
            actions: [
              if (widget.isProfessor)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _mostrarDialogoEdicion,
                ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  currentTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SelectableText(
                  currentUrl,
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              // Aquí se renderiza el reproductor de forma segura
              player, 
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  
}*/




class VideoScreen extends StatefulWidget {
  final String videoTitle;
  final String videoUrl;

  const VideoScreen({
    super.key,
    required this.videoTitle,
    required this.videoUrl,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}


class _VideoScreenState extends State<VideoScreen> {
  // 2. Creamos el controlador para el reproductor de YouTube
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    // 3. Extraemos el ID del video desde la URL que recibimos
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    // 4. Inicializamos el controlador con el ID del video
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '', // Si el ID es nulo, usa uno vacío
      flags: const YoutubePlayerFlags(
        autoPlay: true, // El video empieza a reproducirse automáticamente
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    // 5. Es muy importante liberar los recursos del controlador al salir
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Videos'),
      ),
      // 6. Usamos el widget YoutubePlayer para mostrar el video
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
  
         Center(
              child: Text(
                widget.videoTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          
          const SizedBox(height: 8),

         Flexible(
                  child: SelectableText(
                    widget.videoUrl,
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
         ),  
        
         const SizedBox(height: 8),
         
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.amber,
          ),
        ],
      ),
    );
  }
}