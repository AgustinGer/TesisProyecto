import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: Text(videoTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección para mostrar la URL
            const Text(
              'Enlace del Video:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              videoUrl,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 30),
            
            // Botón para abrir el video
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Abrir Video'),
                onPressed: () => _launchVideoUrl(ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





/*
class Videos extends StatelessWidget {
  const Videos({super.key});

  @override
  Widget build(BuildContext context) {
  //   final colors= Theme.of(context).colorScheme;
    return Scaffold(
       appBar: AppBar(   
   //     backgroundColor: colors.primary,
        title: Text('VIDEOS'),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: SafeArea(
        child: Column(
          children: [
           SizedBox(height: 10),

           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 10),
             child: ListView.builder(
              shrinkWrap: true, 
              itemCount: appMenuItems.length,
              itemBuilder: (context, index){
                return Container(
                 decoration: BoxDecoration(
                 border: BorderDirectional(bottom: BorderSide(color: Colors.grey,width: 1))
                 ),
                  child: Column(          
                    children: [
                     Align(alignment: Alignment.centerLeft,
                      child: Text('Video ${index+1}:',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                      ),
                     Align(alignment: Alignment.centerLeft,
                      child: Text('https://www.youtube.com/watch?v=hT_nvWreIhg',style: TextStyle(fontSize: 14))
                      ),
             
                      SizedBox(height: 10),
                    ],
                  ),
                );                               
              },
             ),
           ),
          ],

        ))
    );
  }
}*/