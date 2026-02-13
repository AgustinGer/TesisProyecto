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