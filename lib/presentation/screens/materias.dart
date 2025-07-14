import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';
import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:go_router/go_router.dart';
//import 'package:go_router/go_router.dart';

// archivo: materias.dart

// 1. El widget ahora es un ConsumerWidget y recibe el courseId
class Materias extends ConsumerWidget {
  final int courseId;
  const Materias({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Observamos el provider, pasándole el ID del curso
    final asyncCourseContent = ref.watch(courseContentProvider(courseId));
    final colors= Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        // El título podría venir del provider también, pero lo dejamos simple por ahora
        title: const Text('Contenido del Curso'),
      ),
      // 3. Usamos .when para manejar los estados de carga
      body: asyncCourseContent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (sections) {
          // Si tenemos datos, construimos la lista de secciones y módulos
          return ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              final List modules = section['modules'] ?? [];
              
              // Aquí puedes construir una UI más compleja, similar a tu maqueta
              return ExpansionTile(
                title: Text(section['name'] ?? 'Sección sin nombre'),
                children: modules.map((module) {
                  final String moduleName = module['name'] ?? 'Módulo sin nombre';
                  final String modname = module['modname'] ?? '';
                  return ListTile(
                    leading: getModuleIcon(modname, colors.primary),// Lógica de iconos
                    title: Text(moduleName),
                    onTap: () {
                      // Obtenemos el tipo de módulo, por ejemplo: 'folder', 'url', 'label', 'resource'.
                      final String modname = module['modname'] ?? '';

                      // Usamos un switch para decidir qué hacer según el tipo de módulo.
                      switch (modname) {
                        
                        // Caso 1: Es una carpeta con archivos.
                        case 'folder':
                        case 'resource': // Un recurso también es un archivo descargable.
                          final List contents = module['contents'] ?? [];
                          if (contents.isNotEmpty) {
                            // Navegamos a la pantalla de recursos y pasamos la lista de archivos.
                            context.push('/recursos', extra: contents);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Este módulo no tiene contenido.')),
                            );
                          }
                          break;

                        // Caso 2: Es un enlace (URL), como un video.
                        case 'url':
                          final List contents = module['contents'] ?? [];
                          if (contents.isNotEmpty) {
                            // Obtenemos la URL externa del primer archivo.
                            final String videoUrl = contents[0]['fileurl'] ?? '';
                            if (videoUrl.isNotEmpty) {
                              // Aquí puedes navegar a una pantalla de video o lanzarla directamente.
                              // Por ahora, la lanzaremos con url_launcher.
                              // Asegúrate de tener la lógica para añadir el token.
                              // _downloadFile(ref, videoUrl); // Reutilizando la función de descarga
                              print('Navegar a video: $videoUrl');
                              context.push('/videos', extra: {'title': module['name'], 'url': videoUrl});
                            }
                          }
                         break;

                        // Caso 3: Es una etiqueta de texto o una página (para la introducción).
                        case 'label':
                        case 'page':
                          final String description = module['description'] ?? 'No hay descripción.';
                          // Navegamos a una nueva pantalla de descripción y le pasamos el texto.
                          print('Navegar a descripción: $description');
                          // context.push('/descripcion', extra: description);
                          break;
                        
                        // Caso por defecto: para cualquier otro tipo de módulo.
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Este tipo de contenido no es soportado aún.')),
                          );
                          break;
                      }
                    },

                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}



Widget getModuleIcon(String modname, Color primaryColor) {
  
  switch (modname) {
    case 'resource':
      return Icon(Icons.archive_sharp, color:primaryColor);
    case 'label':
      return Icon(Icons.info, color: Colors.green); // Cambiado a un ícono más descriptivo
    case 'folder':
      return const Icon(Icons.folder_copy_sharp, color: Colors.yellow); // Cambiado a un ícono de carpeta
    case 'url':
      return Icon(Icons.link, color: Colors.grey); // Cambiado a un ícono de enlace
    default:
      return const Icon(Icons.description_outlined);
  }
}

















/*class Materias extends StatelessWidget {
  const Materias({super.key});

  @override
  Widget build(BuildContext context) {
  // final colors= Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
      //  backgroundColor: colors.primary,
        title: Text('Programacion',style: TextStyle(color: Colors.white)),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: 
      NavegacionMaterias()// ListInicio(),
    );
  }
}

class NavegacionMaterias extends StatelessWidget {
  const NavegacionMaterias({
    super.key,
  });

  final int countActividad=0;
  @override
  Widget build(BuildContext context) {
       final colors= Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column( 
            children: [
            Image(image: NetworkImage('https://img.freepik.com/vector-premium/logo-nombre-universidad-logo-empresa-llamada-universidad_516670-732.jpg'),height:200, width: double.infinity,fit: BoxFit.cover,), 
            
            SizedBox(height: 30),
            
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
            child:ListTile(
            leading: Icon(Icons.bookmark_sharp, color: Colors.green),
            // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
            title: Text('INFORMACION CURSO'),
            ),
          ),
            
            SizedBox(height: 30),
            Text('NO se ha proporcionado informacion del curso actualmente'), 
            SizedBox(height: 30), 
        
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                // color: Colors.white,
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
            child:ListTile(
            leading: Icon(Icons.cases_outlined, color: Colors.blue),
            title: Text('RECURSOS'),
            ),                     
          ),
        
              ListTile(
              leading: Icon(Icons.ios_share  , color: Colors.grey),
              subtitle: Text('Matrial de apoyo'),
              onTap: () {
                context.push('/recursos');
               },
              ),  
            
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
                
        
                child:ListTile(
                leading: Icon(Icons.collections_sharp, color: Colors.red),
                // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
                title: Text('ACTIVIDADES'),

                ),                     
                // chi: Center(child: Text('hola')),
              ),
        
              
         
        
            SizedBox(height: 10), 

          //  Text('actividad 1'),

            Container(
              decoration: BoxDecoration(
                border: BorderDirectional(bottom: BorderSide(color: Colors.black,width: 1))
              ) ,
              child: ListView.builder(
               shrinkWrap: true, 
               itemCount: appMenuItems.length,
               itemBuilder: (context, index){
                 return ListTile(
                  leading: Icon(Icons.description_rounded, color: Colors.yellow),
                  trailing: Icon(Icons.verified_outlined, color: Colors.green,),
                  subtitle: Text('Actividad ${index+1}'),
                  onTap: () {
                     context.push('/actividades');
                   },
                  );               
               },
              ),
            ),
        
            Container(
              //height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                // color: Colors.white,
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
        
                child:ListTile(
                leading: Icon(Icons.video_file, color: Colors.brown),
                // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
                title: Text('VIDEOS'),
                ),                     
              ),
        
              

              ListTile(
              leading: Icon(Icons.video_call_sharp  , color: Colors.grey),
              // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
              subtitle: Text('Videos de apoyo'),
              onTap: () {
                context.push('/videos');
               },
              ),
              SizedBox(height: 10),             
            ],
          ),
        ),
      ));
  }
}*/