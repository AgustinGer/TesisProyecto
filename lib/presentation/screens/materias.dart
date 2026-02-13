import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/moddle_launcher.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/course_actions_provider.dart';
import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:flutter_tesis/provider/user_profile.dart';
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
    final userProfileAsync = ref.watch(userProfileProvider);


    final colors= Theme.of(context).colorScheme;
    final hasNotch = MediaQuery.of(context).viewPadding.top > 35;

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
      // Moodle devuelve 'fullname' y 'profileimageurl' en esta función
        final String studentName = userProfileAsync.value?['fullname'] ?? 'Cargando...';
        final String studentProfileUrl = userProfileAsync.value?['profileimageurl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenido del Curso'),
        actions: [
            Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12, left: 8),
                    child: CircleAvatar(
                      radius: 16, // Tamaño pequeño para el AppBar
                      backgroundColor: Colors.indigo.shade300,
                      backgroundImage: studentProfileUrl.isNotEmpty 
                          ? NetworkImage(studentProfileUrl) 
                          : null,
                      child: studentProfileUrl.isEmpty 
                          ? const Icon(Icons.person, size: 20, color: Colors.white) 
                          : null,
                    ),
                  ),
                ),
              ),
          const SizedBox(width: 8), // Un pequeño espacio al final
        ],
      ),
      
     endDrawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. Espacio para el Notch (SafeArea manual)
                SizedBox(height: hasNotch ? 50 : 20),

                // 2. TU CABECERA PERSONALIZADA (Row con Avatar y Texto)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: colors.primaryContainer,
                        backgroundImage: studentProfileUrl.isNotEmpty
                            ? NetworkImage(studentProfileUrl)
                            : null,
                        child: studentProfileUrl.isEmpty
                            ? const Icon(Icons.person, size: 30, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                               // color: colors.onSurface
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            userRoleAsync.when(
                              data: (roleRaw) {
                                // 1. Lógica del switch para traducir el rol
                                String roleDisplay;
                                switch (roleRaw) {
                                  case 'editingteacher':
                                  case 'teacher':
                                    roleDisplay = 'Profesor';
                                    break;
                                  case 'manager':
                                  case 'coursecreator':
                                    roleDisplay = 'Gestor';
                                    break;
                                  case 'admin':
                                    roleDisplay = 'Administrador';
                                    break;
                                  default:
                                    roleDisplay = 'Estudiante';
                                }

                                // 2. Retornamos el widget usando el texto traducido
                                return Text(
                                  roleDisplay, 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                );
                              },
                              loading: () => const Text(
                                '...', 
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              error: (_, __) => const Text(
                                'Estudiante', 
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                           /* Text(
                              currentRole,
                              //"Estudiante", // O el rol dinámico si lo tienes
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),*/
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. DIVIDER
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
                  child: Divider(),
                ),

                // 4. SECCIÓN "DEL CURSO" (Equivalente a tu "Main")
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
                  child: Text('Acciones del Curso', style: TextStyle(color: Colors.grey)),
                ),

                // Ítems del menú con estilo NavigationDrawerDestination
                _buildDrawerItem(
                  context: context,
                  icon: Icons.assignment_turned_in,
                  text: 'Mis Calificaciones',
                  onTap: () {
                    Navigator.pop(context);

                    final roleC = userRoleAsync.value ?? 'student';

                    // 2. Definimos quién es "Profesor"
                    final isProfesorCalificacion = roleC == 'admin' ||
                        roleC == 'manager' ||
                        roleC == 'editingteacher' ||
                        roleC == 'teacher';
                   // context.push('/mis-notas/$courseId');
                  if (isProfesorCalificacion) {
                      // SI ES PROFESOR: Va a la lista de alumnos
                      context.push('/lista-estudiantes/$courseId');
                    } else {
                      // SI ES ALUMNO: Va a sus propias notas
                      context.push('/mis-notas/$courseId');
                    }
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.chat_bubble,
                  text: 'Mensajería',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/mensajes');
                  },
                ),

                // 5. SECCIÓN "OPCIONES" (Equivalente a tu "More options")
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
                  child: Divider(),
                ),
                 const Padding(
                  padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
                  child: Text('Opciones', style: TextStyle(color: Colors.grey)),
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  text: 'Cerrar Sesión',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    // Tu lógica de logout
                  },
                ),
              ],
            ),
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
               /*     trailing: isProfesorAsign
                         ? IconButton(
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: () {
                            // Extraemos los datos necesarios para la edición
                            final int moduleId = int.parse(module['id'].toString());
                            final String modType = module['modname'] ?? '';
                            
                            print('Editando módulo ID: $moduleId tipo: $modType');
                            
                            // Navegamos a la pantalla de edición pasándole el ID y el tipo
                            // Puedes usar rutas de GoRouter según lo tengas configurado
                            context.push('/editar-modulo/$courseId/$moduleId', extra: module);
                          },
                        )
                      : null,*/
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
                             // final int moduleId = int.parse(module['id'].toString());
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

                        // Dentro del switch (modname) en Materias.dart

                      // Dentro del switch (modname) en tu ListView de Materias

                      case 'glossary':
                        final int glossaryInstanceId = int.parse(module['instance'].toString());
                        final int cmid = int.parse(module['id'].toString());
                        final String glossaryTitle = module['name'] ?? 'Glosario';

                        context.push(
                          '/glosario/$glossaryInstanceId', 
                          extra: {
                            'title': glossaryTitle,
                            'contextId': cmid, 
                            'courseId': courseId, // <--- NUEVO: Pasamos el ID del curso
                            'isTeacher': isProfesorAsign,
                          } 
                        );
                        break;        

                        case 'data': // 'data' es el nombre interno de Moodle para Base de Datos
                          final int dataInstanceId = int.parse(module['instance'].toString());
                          final int cmid = int.parse(module['id'].toString());
                          final String dataTitle = module['name'] ?? 'Base de Datos';
                          
                          // EXTRAEMOS EL CONTEXT ID (Vital para calificar)
                          // Moodle suele devolverlo en la propiedad 'contextid' dentro del módulo
                          final int contextId = module['contextid'] != null 
                              ? int.parse(module['contextid'].toString()) 
                              : 0;

                          context.push(
                            '/basedatos/$dataInstanceId', 
                            extra: {
                              'title': dataTitle,
                              'moduleId': cmid,
                              
                              // --- NUEVOS PARÁMETROS OBLIGATORIOS ---
                              'contextId': contextId,        // Necesario para el modal de calificación
                              'courseId': courseId,          // Necesario para buscar la configuración
                              'isTeacher': isProfesorAsign,  // Necesario para mostrar el botón
                            } 
                          );
                          break;
                                            
                      case 'choice':
                        final int choiceInstanceId = int.parse(module['instance'].toString());
                        final int cmid = int.parse(module['id'].toString());
                        final String choiceTitle = module['name'] ?? 'Elección';

                        context.push(
                          '/eleccion', 
                          extra: {
                            'choiceId': choiceInstanceId,
                            'moduleId': cmid,
                            'title': choiceTitle,
                            'courseId': courseId, // <--- AGREGAR ESTO (Es vital)
                            'isTeacher': isProfesorAsign,
                          }
                        );
                        break;

                        // CASO 1: H5P Nativo (Azul)
                        case 'h5pactivity': 
                          final int cmid = int.parse(module['id'].toString());
                          final String title = module['name'] ?? 'Actividad H5P';

                          context.push(
                            '/h5p', 
                            extra: {
                              'moduleId': cmid,
                              'title': title,
                              'modName': 'h5pactivity', // <--- Importante
                            }
                          );
                          break;

                        // CASO 2: H5P Plugin (Negro - hvp)
                        case 'hvp': 
                          final int cmid = int.parse(module['id'].toString());
                          final String title = module['name'] ?? 'Contenido Interactivo';

                          context.push(
                            '/h5p', 
                            extra: {
                              'moduleId': cmid,
                              'title': title,
                              'modName': 'hvp', // <--- Importante
                            }
                          );
                          break;

                          // En Materias.dart -> dentro del switch (modname)

                      case 'lesson':
                        final int cmid = int.parse(module['id'].toString());
                        final String lessonTitle = module['name'] ?? 'Lección';

                        context.push(
                          '/lesson', 
                          extra: {
                            'moduleId': cmid,
                            'title': lessonTitle,
                          }
                        );
                        break;


                        case 'imscp':
                          final int cmid = int.parse(module['id'].toString());
                          final String imsTitle = module['name'] ?? 'Paquete IMS';

                          context.push(
                            '/imscp', 
                            extra: {
                              'moduleId': cmid,
                              'title': imsTitle,
                            }
                          );
                        break;


                        case 'scorm':
                          final int cmid = int.parse(module['id'].toString());
                          final String scormTitle = module['name'] ?? 'Paquete SCORM';

                          context.push(
                            '/scorm', 
                            extra: {
                              'moduleId': cmid,
                              'title': scormTitle,
                            }
                          );
                        break;


                        case 'feedback':
                          final int cmid = int.parse(module['id'].toString());
                          final String feedbackTitle = module['name'] ?? 'Retroalimentación';

                          context.push(
                            '/feedback', 
                            extra: {
                              'moduleId': cmid,
                              'title': feedbackTitle,
                            }
                          );
                        break;

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

Widget _buildDrawerItem({
    required IconData icon, 
    required String text, 
    required VoidCallback onTap,
    required BuildContext context,
    Color? textColor,
    Color? iconColor,
  }) {

    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? colors.onSurface),
        title: Text(text, style: TextStyle(color: textColor ?? colors.onSurface)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // Forma redondeada Material 3
        onTap: onTap,
      ),
    );
  }
