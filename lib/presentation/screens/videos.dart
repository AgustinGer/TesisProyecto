import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// 1. Convertimos a un StatefulWidget
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


















/*
class VideoScreen extends ConsumerWidget {
  // 2. Recibe el título y la URL del video en su constructor.
  final String videoTitle;
  final String videoUrl;

  const VideoScreen({
    super.key,
    required this.videoTitle,
    required this.videoUrl,
  });

  // Función para lanzar la URL del video
  Future<void> _launchVideoUrl(WidgetRef ref) async {
    final token = ref.read(authTokenProvider);
    if (token == null) return;

    // Construimos la URL correctamente, añadiendo el token
    String urlWithToken;
    if (videoUrl.contains('?')) {
      urlWithToken = '$videoUrl&token=$token';
    } else {
      urlWithToken = '$videoUrl?token=$token';
    }

    final uri = Uri.parse(urlWithToken);
    
    // Usamos url_launcher para abrir el enlace en una app externa (como YouTube o el navegador)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('No se pudo lanzar la URL: $uri');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        // 3. Mostramos el título del video en la barra superior.
        title: Text('Enlace del Video'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección para mostrar la URL
            Text(
              videoTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
           
            Row(
              children: [
                // El Expanded permite que el texto ocupe todo el espacio disponible
                Flexible(
                  child: SelectableText(
                    videoUrl,
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
                // El botón de icono al final de la fila
                IconButton(
                  iconSize: 42,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.play_circle_outline),
                  tooltip: 'Abrir video',
                  onPressed: () => _launchVideoUrl(ref),
                ),
              ],
            ),
            Divider()
          ],
        ),
      ),
    );
  }
}*/