import 'package:flutter/material.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_tesis/provider/course_actions_provider.dart';
//import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';



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
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    
    // Convertimos la URL a ID
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: false, // Poner true si quieres forzar HD
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos YoutubePlayerBuilder para soportar Pantalla Completa
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.amber,
        onReady: () {
          _isPlayerReady = true;
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reproductor de Video'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EL REPRODUCTOR
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: player,
                ),
                
                const SizedBox(height: 20),
                
                // TÍTULO
                Text(
                  widget.videoTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 10),
                
                // LINK (Opcional)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.videoUrl,
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/*
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
}*/