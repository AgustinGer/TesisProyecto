import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/moddle_launcher.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/course_actions_provider.dart';
import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:flutter_tesis/provider/user_role_provider.dart';
import 'package:go_router/go_router.dart';

// 1. El widget ahora es un ConsumerWidget y recibe el courseId
class Materias extends ConsumerWidget {
  final int courseId;
  const Materias({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Observamos el provider, pasándole el ID del curso
    //final userRole = ref.watch(userRoleProvider);
    final userRoleAsync = ref.watch(userRole(courseId));
    final asyncCourseContent = ref.watch(courseContentProvider(courseId));
    final colors= Theme.of(context).colorScheme;

    // Extraemos el valor del rol de forma segura
    final String currentRole = userRoleAsync.value ?? 'student';
    final bool isProfesorAsign = currentRole == 'admin' || 
                          currentRole == 'manager' || 
                          currentRole == 'editingteacher' || 
                          currentRole == 'teacher';

    return asyncCourseContent.when(
    loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    data: (sections) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenido del Curso'),
      ),
      
            // --- NUEVO: Botón flotante condicionado al rol de profesor ---
      floatingActionButton: userRoleAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (role) {
          final bool isProfesor = role == 'admin' ||
              role == 'manager' ||
              role == 'editingteacher' ||
              role == 'teacher';

          if (!isProfesor) return null;

          return FloatingActionButton.extended(
            onPressed: () {
              _mostrarOpcionesDeActividad(context, ref, courseId, sections);
            },
            label: const Text('Nueva Actividad'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.indigo,
          );
        },
      ),

      // 3. Usamos .when para manejar los estados de carga
      body: RefreshIndicator(
          onRefresh: () => ref.refresh(courseContentProvider(courseId).future),
          child: ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              final List modules = section['modules'] ?? [];
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
                        case 'resource':
                          final List contents = module['contents'] ?? [];
                          if (contents.isNotEmpty) {
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
                         
                                                // Dentro del switch (modname) en el onTap
                        case 'assign':
                          // El ID de la tarea se encuentra en la clave 'instance' del módulo
                          final int assignmentId = module['instance'];
                         //context.push('/actividades/$courseId/$assignmentId');
                          if (isProfesorAsign) {
                            // Si es profesor, lo llevamos a la pantalla donde ve las entregas de los alumnos
                            print('Navegando como Profesor a gestión de tarea: $assignmentId');
                            context.push('/estudiante-tarea/$courseId/$assignmentId');
                          } else {
                            // Si es alumno, va a la pantalla normal de entrega
                            print('Navegando como Estudiante a entrega de tarea: $assignmentId');
                            context.push('/actividades/$courseId/$assignmentId');
                          }                        
                        break;
                        // Caso 3: Es una etiqueta de texto o una página (para la introducción).
                        case 'label':
                        case 'page':
                          final String description = module['description'] ?? 'No hay descripción.';
                          // Navegamos a una nueva pantalla de descripción y le pasamos el texto.
                          print('Navegar a descripción: $description');
                          context.push('/description', extra: description);
                          break;
                        
                        case 'forum':
                        // El ID del foro se encuentra en la clave 'instance' del módulo
                        final int forumId = module['instance'];
                        print('DEBUG módulo forum: $module');
                        context.push('/foro/$forumId');
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
          ),
      ),
     );
    }
   );
  }
}



void _mostrarOpcionesDeActividad(BuildContext context, WidgetRef ref, int courseId, List sections) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.library_add_outlined, color: Colors.indigo),
              title: const Text('Añadir Nueva Sección'),
              onTap: () {
                Navigator.pop(context);
                // Ahora estas variables ya son accesibles aquí
              //  final int lastSectionId = sections.last['id'];
                final int lastSectionId = int.parse(sections.last['id'].toString());
                _dialogoNuevaSeccion(
                  context, 
                  ref, 
                  courseId, 
                  lastSectionId
                 );
                },
              ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.orange),
              title: const Text('Crear Tarea (Assign)'),
              onTap: () {
                Navigator.pop(context); // Cierra el menú inferior
                
                // Navegación con GoRouter
                // Pasamos el ID en la URL y el objeto complejo (sections) en el extra
                context.push(
                  '/crear-tarea/$courseId', 
                  extra: sections
                );
              },     
            ),


           /* ListTile(
              leading: const Icon(Icons.forum, color: Colors.blue),
              title: const Text('Crear Foro'),
              onTap: () => Navigator.pop(context),
            ),*/
            
            ListTile(
              leading: const Icon(Icons.link, color: Colors.grey),
              title: const Text('Añadir Enlace (URL)'),
              onTap: () async {
                  Navigator.pop(context); // Cierra el menú

                  // 1️⃣ Obtener secciones actuales
                  if (sections.isEmpty) return;

                  // 2️⃣ Elegir sección
                  final selectedSectionNumber = await seleccionarSeccion(
                    context,
                    sections,
                  );

                  if (selectedSectionNumber == null) return;

                  // 3️⃣ URL base de Moodle
                  final moodleBaseUrl = ref.read(moodleBaseUrlProvider);

                  // 4️⃣ Abrir formulario oficial de Moodle
                  await abrirFormularioCrearUrl(
                    moodleBaseUrl: moodleBaseUrl,
                    courseId: courseId,
                    sectionNumber: selectedSectionNumber,
                  );
                },
              //  onTap: () {
              //  Navigator.pop(context);
              //  context.push('/crear-url/$courseId', extra: sections);
              //}, 
            ),
            // --- NUEVO: Carpeta (Folder) ---
            ListTile(
              leading: const Icon(Icons.folder_copy_sharp, color: Colors.yellow),
              title: const Text('Añadir Carpeta'),
              onTap: () async {
                final BuildContext currentContext = context;
                Navigator.pop(currentContext);

                final sections = await ref.read(courseContentProvider(courseId).future);
                if (sections.isEmpty) return;

                final selectedSectionNumber = await seleccionarSeccion(
                  currentContext,
                  sections,
                );

                if (selectedSectionNumber == null) return;

                final moodleBaseUrl = ref.read(moodleBaseUrlProvider);

                await abrirFormularioCrearCarpeta(
                  moodleBaseUrl: moodleBaseUrl,
                  courseId: courseId,
                  sectionNumber: selectedSectionNumber,
                );
              },

            ),

            // --- NUEVO: Recurso/Archivo (Resource) ---
            ListTile(
              leading: Icon(Icons.archive_sharp, color: Colors.green),
              title: const Text('Subir Archivo (Recurso)'),
              onTap: () async {
                Navigator.pop(context);

                final sections = await ref.read(courseContentProvider(courseId).future);
                if (!context.mounted) return;

                final selectedSectionNumber = await seleccionarSeccion(
                  context,
                  sections,
                );

                if (selectedSectionNumber == null) return;

                final moodleBaseUrl = ref.read(moodleBaseUrlProvider);

                await abrirFormularioCrearRecurso(
                  moodleBaseUrl: moodleBaseUrl,
                  courseId: courseId,
                  sectionNumber: selectedSectionNumber,
                );
              },


            ),
          ],
        ),
      );
    },
  );
}


Future<int?> seleccionarSeccion(
  BuildContext context,
  List sections,
) {
  return showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final sec = sections[index];
          return ListTile(
            title: Text(sec['name'] ?? 'Sección sin nombre'),
            onTap: () {
              Navigator.pop(context, sec['section']);
            },
          );
        },
      );
    },
  );
}



// Nota: Asegúrate de pasar 'ref' y 'sections.length' a esta función
void _dialogoNuevaSeccion(BuildContext context, WidgetRef ref, int courseId, int lastSectionId) {
  final TextEditingController sectionController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Nueva Sección'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(labelText: 'Nombre de la sección'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
// En tu función _dialogoNuevaSeccion
        onPressed: () async {
        final nombre = sectionController.text;
        if (nombre.isEmpty) return;

        // 1. Capturar IDs actuales convirtiéndolos a int (Moodle los manda como String)
        final oldContent = await ref.read(courseContentProvider(courseId).future);
        final Set<int> oldIds = oldContent.map((s) => int.parse(s['id'].toString())).toSet();

        // 2. Crear la sección
        final success = await ref.read(courseActionsProvider)
                                .crearSeccionMoodle(courseId, lastSectionId);

        if (success) {
          if (context.mounted) Navigator.pop(context); 

          // 3. Refrescar datos
          ref.invalidate(courseContentProvider(courseId));
          await Future.delayed(const Duration(milliseconds: 1000));
          final newContent = await ref.read(courseContentProvider(courseId).future);

          // 4. Identificar el ID nuevo comparando como enteros
          final newSection = newContent.where((s) {
            final id = int.parse(s['id'].toString());
            return !oldIds.contains(id);
          }).firstOrNull;

          if (newSection != null) {
            final int newId = int.parse(newSection['id'].toString());
            print('Renombrando sección detectada con ID: $newId');

            // 5. Llamada final de renombrado
            await ref.read(courseActionsProvider).editarNombreSeccion(newId, nombre);
            
            // Refresco final de la UI
            ref.invalidate(courseContentProvider(courseId));
          }
        }
      },

            child: const Text('Crear'),
          ),
        ],
      );
    },
  );
}

Widget getModuleIcon(String modname, Color primaryColor) {
  
  switch (modname) {
     case 'assign': // <-- Añade este caso para las tareas
      return Icon(Icons.assignment_turned_in_outlined, color: Colors.orange.shade700);
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
