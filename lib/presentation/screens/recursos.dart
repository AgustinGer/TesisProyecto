import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';







// Es un ConsumerWidget para poder leer el token del provider
class RecursosScreen extends ConsumerWidget {
  final List<dynamic> files;

  const RecursosScreen({super.key, required this.files});

  // Función para obtener un ícono según el tipo de archivo
Icon _getFileIcon(String mimetype) {
  // Nuevo: para cualquier tipo de imagen (jpg, png, gif, etc.)
  if (mimetype.contains('image')) {
    return const Icon(Icons.image, color: Colors.purple);
  }
  
  // Para archivos PDF
  if (mimetype.contains('pdf')) {
    return const Icon(Icons.picture_as_pdf, color: Colors.red);
  }

  // Para archivos de Word
  if (mimetype.contains('word')) {
    return const Icon(Icons.description, color: Colors.blue);
  }
  
  // Para archivos de Excel
  if (mimetype.contains('spreadsheet') || mimetype.contains('excel') || mimetype.contains('csv')) {
    return const Icon(Icons.grid_on_rounded, color: Colors.green); // Ícono más representativo
  }
  
  // Ícono por defecto para cualquier otro tipo de archivo
  return const Icon(Icons.attach_file);
}


Future<void> _downloadFile(WidgetRef ref, String fileUrl) async {
  final token = ref.read(authTokenProvider);
  if (token == null) return;

  // --- LÓGICA CORREGIDA PARA CONSTRUIR LA URL ---
  String urlWithToken;
  if (fileUrl.contains('?')) {
    // Si ya tiene parámetros, añadimos el token con &
    urlWithToken = '$fileUrl&token=$token';
  } else {
    // Si no tiene parámetros, añadimos el token con ?
    urlWithToken = '$fileUrl?token=$token';
  }
  // ------------------------------------------------

  print('--- Intentando abrir URL CORREGIDA: $urlWithToken ---');

  final uri = Uri.parse(urlWithToken);
  
  if (await canLaunchUrl(uri)) {
    // Usamos el modo externo para que el navegador del sistema maneje la descarga
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print('No se pudo lanzar la URL: $uri');
  }
}
  // Función para iniciar la descarga
 /* Future<void> _downloadFile(WidgetRef ref, String fileUrl) async {
    final token = ref.read(authTokenProvider); // Lee el token
    if (token == null) return;

    // AÑADIMOS EL TOKEN A LA URL PARA TENER PERMISO DE DESCARGA
    final urlWithToken = '$fileUrl?token=$token';
     print('--- Intentando abrir esta URL: $urlWithToken ---');
    final uri = Uri.parse(urlWithToken);
    
    // Usamos url_launcher para abrir el enlace en un navegador externo
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Manejar el error si no se puede abrir la URL
      print('No se pudo lanzar la URL: $uri');
    }
  }*/

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos'),
      ),
      body: ListView.separated(
        
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final String filename = file['filename'] ?? 'Archivo sin nombre';
          final String fileUrl = file['fileurl'] ?? '';
          final String mimetype = file['mimetype'] ?? '';

          return ListTile(
            leading: _getFileIcon(mimetype),
            title: Text(filename),
            onTap: () {
              if (fileUrl.isNotEmpty) {
                _downloadFile(ref, fileUrl);
              }
            },         
          );        
        }, 
        separatorBuilder: (context,index){
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: Divider(),
          );
       },   
      ),
    );
    
  }
}

/*
class Recursos extends StatelessWidget {
  const Recursos({super.key});

  @override
  Widget build(BuildContext context) {
    final colors= Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        
    //    backgroundColor: colors.primary,
        title: Text('RECURSOS'),
        centerTitle: true, 
        //centrar en ios y android
      ),

      body: SafeArea(
        child: Column(
          children: [
              Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: colors.secondary
                )                
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Unidad recursos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),

              Container(
              decoration: BoxDecoration(
                //border: BorderDirectional(bottom: BorderSide(color: Colors.black,width: 1))
              ) ,
              child: ListView.builder(
               shrinkWrap: true, 
               itemCount: appMenuItems.length,
               itemBuilder: (context, index){
                 return ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                //  trailing: Icon(Icons.verified_outlined, color: Colors.green,),
                  title: Text('Recurso PDF ${index+1}'),
                  );               
               },
              ),
            ),

            Container(
              decoration: BoxDecoration(
                //border: BorderDirectional(bottom: BorderSide(color: Colors.black,width: 1))
              ) ,
              child: ListView.builder(
               shrinkWrap: true, 
               itemCount: appMenuItems.length,
               itemBuilder: (context, index){
                 return ListTile(
                  leading: Icon(Icons.insert_drive_file, color: Colors.green),
                //  trailing: Icon(Icons.verified_outlined, color: Colors.green,),
                  title: Text('Excel ${index+1}'),
                  );                                
               },
              ),
            ),
          ],
      )),
    );
  }
}*/