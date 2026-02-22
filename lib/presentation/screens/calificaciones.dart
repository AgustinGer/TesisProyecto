import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/shared/grade.dart';
import 'package:flutter_tesis/provider/course_content_provider.dart';
import 'package:flutter_tesis/provider/notas_provider.dart';
import 'package:go_router/go_router.dart';







/*class MisNotasScreen extends ConsumerWidget {
  final int courseId;
  final int? userId; //opcional
  const MisNotasScreen({super.key, required this.courseId, this.userId,});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // USAMOS EL NUEVO PROVIDER
    final gradesAsync = ref.watch(courseGradesProvider((courseId: courseId, userId: userId)),);

// 🔥 NUEVO: Traemos el contenido del curso (que ya está en caché) para buscar los IDs que faltan
   // final courseContentAsync = ref.watch(courseContentProvider(courseId));
    //final List courseSections = courseContentAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Calificaciones')),



      body: gradesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (grades) {
          if (grades.isEmpty) return const Center(child: Text('No hay notas disponibles.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final item = grades[index];
              
              // LOGICA MEJORADA PARA EL NOMBRE
              String displayName = item.itemname;
              
              // Si Moodle dice que este item es el total del curso o categoría
              if (item.isCategory || displayName == 'Elemento de calificación') {
                displayName = 'Total del Curso';
              }
              // Si es tipo categoría (total), lo resaltamos
              final isTotal = item.isCategory || item.itemname.toLowerCase().contains('total');

              return Card(
                elevation: isTotal ? 4 : 1,
                color: isTotal ? Colors.indigo.shade50 : Colors.white,
                child: 
                
                ListTile(
                title: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.sectionName != null)
                      Text(
                        'Unidad: ${item.sectionName}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    Text('Rango: ${item.rangeformatted}'),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.gradeformatted == '-' ? Colors.grey[300] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.gradeformatted,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                
                // onTap: () {
                onTap: isTotal
                    ? null
                    : () async {
                        // 1️⃣ Validaciones
                        if (item.isCategory || item.iteminstance == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Este elemento no es una actividad')),
                          );
                          return;
                        }

                        final int instanceId = item.iteminstance!;
                        final String moduleType = item.itemmodule;
                        final String activityTitle = item.itemname;
                        
                        // 🔑 CLAVE: Si userId != null → es el profesor viendo a un alumno
                        final bool isTeacher = userId != null;

                        // Buscamos el cmid y contextId perdidos buscando en courseSections
                        int cmid = 0;
                        int contextId = 0;

                     /*   for (var section in courseSections) {
                          final modules = section['modules'] ?? [];
                          for (var mod in modules) {
                            // Comparamos el tipo de módulo y el ID de instancia
                            if (mod['modname'] == moduleType && mod['instance'].toString() == instanceId.toString()) {
                              cmid = int.parse(mod['id'].toString());
                              if (mod['contextid'] != null) {
                                contextId = int.parse(mod['contextid'].toString());
                              }
                              break; // Lo encontramos, salimos del bucle interior
                            }
                          }
                          if (cmid != 0) break; // Salimos del bucle exterior
                        }*/

                        try {
                          // 🔥 CRÍTICO: Usamos 'await' y '.future' para GARANTIZAR que tengamos los datos del curso
                          final courseSections = await ref.read(courseContentProvider(courseId).future);
                          
                          for (var section in courseSections) {
                            final modules = section['modules'] ?? [];
                            for (var mod in modules) {
                              if (mod['modname'] == moduleType && mod['instance'].toString() == instanceId.toString()) {
                                cmid = int.parse(mod['id'].toString());
                                if (mod['contextid'] != null) {
                                  contextId = int.parse(mod['contextid'].toString());
                                }
                                break;
                              }
                            }
                            if (cmid != 0) break;
                          }
                        } catch (e) {
                          print("Error buscando CMID: $e");
                        }

                        if (!context.mounted) return;

                        // 🛑 SEGURO ANTI-ERRORES MOODLE
                        // Si después de buscar, el CMID sigue siendo 0, abortamos la navegación
                        if (cmid == 0 && (moduleType == 'data' || moduleType == 'workshop' || moduleType == 'quiz' || moduleType == 'forum')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo localizar el ID del módulo. Regresa a "Materias" para refrescar el curso.'), 
                              backgroundColor: Colors.red
                            ),
                          );
                          return; // Evita que se abra la pantalla con datos corruptos
                        }

                        switch (moduleType) {
                          case 'assign':
                            if (isTeacher) {
                              await context.push('/calificar-tarea/$courseId/$instanceId/$userId', extra: activityTitle);
                            } else {
                              await context.push('/actividades/$courseId/$instanceId');
                            }
                            break;

                          case 'workshop':
                            await context.push(
                              '/workshop', 
                              extra: {
                                'instanceId': instanceId,
                                'courseId': courseId,
                                //'cmid': 0, // La API de notas no devuelve el cmid, pasamos 0 o podrías cruzar datos luego
                                'cmid': cmid,
                                'title': activityTitle,
                              }
                            );
                            break;

                          case 'quiz':
                            await context.push(
                              '/quiz', 
                              extra: {
                                'instanceId': instanceId,
                                'courseId': courseId,
                                //'cmid': 0, 
                                'title': activityTitle,
                                'cmid': cmid,
                              }
                            );
                            break;

                          case 'forum':
                            await context.push(
                              '/forum', 
                              extra: {
                                'instanceId': instanceId,
                                'courseId': courseId,
                               // 'cmid': 0,
                                'cmid': cmid,
                                'title': activityTitle,
                              }
                            );
                            break;

                          case 'data': // Base de Datos
                            await context.push(
                              '/basedatos/$instanceId', 
                              extra: {
                                'title': activityTitle,
                              //  'moduleId': 0, // Se usaría CMID, pasamos 0
                              //  'contextId': 0, 
                                'moduleId': cmid,       // 🔥 AHORA PASAMOS EL CMID REAL
                                'contextId': contextId,
                                'courseId': courseId,
                                'isTeacher': isTeacher,
                              }
                            );
                            break;

                          case 'glossary':
                            await context.push(
                              '/glosario/$instanceId', 
                              extra: {
                                'title': activityTitle,
                                //'contextId': 0,
                                'contextId': cmid,
                                'courseId': courseId,
                                'isTeacher': isTeacher,
                              }
                            );
                            break;

                          case 'choice':
                            await context.push(
                              '/eleccion', 
                              extra: {
                                'choiceId': instanceId,
                                //'moduleId': 0,
                                'moduleId': cmid,
                                'courseId': courseId,
                                'title': activityTitle,
                                'isTeacher': isTeacher,
                              }
                            );
                            break;

                          case 'lesson':
                            await context.push(
                              '/lesson', 
                              extra: {
                               // 'moduleId': instanceId,
                                'moduleId': cmid,  
                                'title': activityTitle,
                              }
                            );
                            break;

                          case 'h5pactivity':
                          case 'hvp':
                            await context.push(
                              '/h5p', 
                              extra: {
                                //'moduleId': instanceId,
                                'moduleId': cmid,
                                'title': activityTitle,
                                'modName': moduleType,
                              }
                            );
                            break;

                          case 'scorm':
                            await context.push(
                              '/scorm', 
                              extra: {
                               // 'moduleId': instanceId,
                                'moduleId': cmid,
                                'title': activityTitle,
                              }
                            );
                            break;

                          default:
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('La vista directa para "$moduleType" desde calificaciones aún no está configurada.')),
                            );
                            break;
                        }

                        if (context.mounted) {
                          ref.invalidate(courseGradesProvider((courseId: courseId, userId: userId)));
                        }

                      },
               ),
              );
            },
          );
        },
      ),
    );
  }
}


final gradesWithSectionProvider =
    FutureProvider.family<List<GradeItem>,
        ({int courseId, int? userId})>((ref, params) async {

  final grades =
      await ref.watch(courseGradesProvider(params).future);

  final modules =
      await ref.watch(courseContentProvider(params.courseId).future);

  // Creamos un mapa para búsqueda rápida
  final moduleMap = {
    for (final m in modules)
      '${m.modname}_${m.instance}': m.sectionName
  };

  for (final grade in grades) {
    if (grade.iteminstance != null) {
      final key = '${grade.itemmodule}_${grade.iteminstance}';
      grade.sectionName = moduleMap[key];
    }
  }

  return grades;
});*/


class MisNotasScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int? userId; //opcional
  
  const MisNotasScreen({super.key, required this.courseId, this.userId});

  @override
  ConsumerState<MisNotasScreen> createState() => _MisNotasScreenState();
}

class _MisNotasScreenState extends ConsumerState<MisNotasScreen> {

  @override
  void initState() {
    super.initState();
    // 🔥 MAGIA 1: Forzamos la recarga al abrir la pantalla
    // Inmediatamente después de dibujar la pantalla, borramos la caché de notas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(courseGradesProvider((courseId: widget.courseId, userId: widget.userId)));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Recuerda usar "widget.courseId" y "widget.userId" ahora que es un StatefulWidget
    final gradesAsync = ref.watch(courseGradesProvider((courseId: widget.courseId, userId: widget.userId)));
    
 
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Calificaciones')),
      body: gradesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (grades) {
          if (grades.isEmpty) return const Center(child: Text('No hay notas disponibles.'));

          // 🔥 MAGIA 2: Añadimos RefreshIndicator para recargar deslizando hacia abajo
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(courseGradesProvider((courseId: widget.courseId, userId: widget.userId)));
              // Esperamos a que la nueva petición termine para ocultar la ruedita de carga
              try {
                await ref.read(courseGradesProvider((courseId: widget.courseId, userId: widget.userId)).future);
              } catch (_) {}
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final item = grades[index];
                
                String displayName = item.itemname;
                
                if (item.isCategory || displayName == 'Elemento de calificación') {
                  displayName = 'Total del Curso';
                }
                
                final isTotal = item.isCategory || item.itemname.toLowerCase().contains('total');

                return Card(
                  elevation: isTotal ? 4 : 1,
                  color: isTotal ? Colors.indigo.shade50 : Colors.white,
                  child: ListTile(
                    title: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.sectionName != null)
                          Text(
                            'Unidad: ${item.sectionName}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        Text('Rango: ${item.rangeformatted}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.gradeformatted == '-' ? Colors.grey[300] : Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.gradeformatted,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    // Aquí va tu onTap con el switch que arreglamos en el mensaje anterior
                    onTap: isTotal
                        ? null
                        : () async {
                            if (item.isCategory || item.iteminstance == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Este elemento no es una actividad navegable')),
                              );
                              return;
                            }

                            final int instanceId = item.iteminstance!;
                            final String moduleType = item.itemmodule; 
                            final String activityTitle = item.itemname;
                            final bool isTeacher = widget.userId != null;

                            int cmid = 0;
                            int contextId = 0;

                            try {
                              // Asegúrate de usar widget.courseId
                              final sections = await ref.read(courseContentProvider(widget.courseId).future);
                              
                              for (var section in sections) {
                                final modules = section['modules'] ?? [];
                                for (var mod in modules) {
                                  if (mod['modname'] == moduleType && mod['instance'].toString() == instanceId.toString()) {
                                    cmid = int.parse(mod['id'].toString());
                                    if (mod['contextid'] != null) {
                                      contextId = int.parse(mod['contextid'].toString());
                                    }
                                    break;
                                  }
                                }
                                if (cmid != 0) break;
                              }
                            } catch (e) {
                              print("Error buscando CMID: $e");
                            }

                            if (!context.mounted) return;

                            if (cmid == 0 && (moduleType == 'data' || moduleType == 'workshop' || moduleType == 'quiz' || moduleType == 'forum')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No se pudo localizar el ID del módulo. Regresa a "Materias" para refrescar el curso.'), 
                                  backgroundColor: Colors.red
                                ),
                              );
                              return; 
                            }

                            // --- TU SWITCH DE RUTAS AQUÍ ---
                            // (Pega el mismo switch que hicimos antes, solo asegúrate 
                            // de cambiar courseId por widget.courseId y userId por widget.userId)
                            // ...
                              switch (moduleType) {
                                case 'assign':
                                  if (isTeacher) {
                                    // 🔥 CORRECCIÓN: Usamos ${} para leer las propiedades del widget
                                    await context.push('/calificar-tarea/${widget.courseId}/$instanceId/${widget.userId}', extra: activityTitle);
                                  } else {
                                    // 🔥 CORRECCIÓN: Aquí también usamos ${}
                                    await context.push('/actividades/${widget.courseId}/$instanceId');
                                  }
                                  break;
                                  
                                case 'workshop':
                                  await context.push(
                                    '/workshop', 
                                    extra: {
                                      'instanceId': instanceId,
                                      'courseId': widget.courseId,
                                      //'cmid': 0, // La API de notas no devuelve el cmid, pasamos 0 o podrías cruzar datos luego
                                      'cmid': cmid,
                                      'title': activityTitle,
                                    }
                                  );
                                  break;

                                case 'quiz':
                                  await context.push(
                                    '/quiz', 
                                    extra: {
                                      'instanceId': instanceId,
                                      'courseId': widget.courseId,
                                      //'cmid': 0, 
                                      'title': activityTitle,
                                      'cmid': cmid,
                                    }
                                  );
                                  break;

                                case 'forum':
                                  await context.push(
                                    '/forum', 
                                    extra: {
                                      'instanceId': instanceId,
                                      'courseId': widget.courseId,
                                    // 'cmid': 0,
                                      'cmid': cmid,
                                      'title': activityTitle,
                                    }
                                  );
                                  break;

                                case 'data': // Base de Datos
                                  await context.push(
                                    '/basedatos/$instanceId', 
                                    extra: {
                                      'title': activityTitle,
                                    //  'moduleId': 0, // Se usaría CMID, pasamos 0
                                    //  'contextId': 0, 
                                      'moduleId': cmid,       // 🔥 AHORA PASAMOS EL CMID REAL
                                      'contextId': contextId,
                                      'courseId': widget.courseId,
                                      'isTeacher': isTeacher,
                                    }
                                  );
                                  break;

                                case 'glossary':
                                  await context.push(
                                    '/glosario/$instanceId', 
                                    extra: {
                                      'title': activityTitle,
                                      //'contextId': 0,
                                      'contextId': cmid,
                                      'courseId': widget.courseId,
                                      'isTeacher': isTeacher,
                                    }
                                  );
                                  break;

                                case 'choice':
                                  await context.push(
                                    '/eleccion', 
                                    extra: {
                                      'choiceId': instanceId,
                                      //'moduleId': 0,
                                      'moduleId': cmid,
                                      'courseId': widget.courseId,
                                      'title': activityTitle,
                                      'isTeacher': isTeacher,
                                    }
                                  );
                                  break;

                                case 'lesson':
                                  await context.push(
                                    '/lesson', 
                                    extra: {
                                    // 'moduleId': instanceId,
                                      'moduleId': cmid,  
                                      'title': activityTitle,
                                    }
                                  );
                                  break;

                                case 'h5pactivity':
                                case 'hvp':
                                  await context.push(
                                    '/h5p', 
                                    extra: {
                                      //'moduleId': instanceId,
                                      'moduleId': cmid,
                                      'title': activityTitle,
                                      'modName': moduleType,
                                    }
                                  );
                                  break;

                                case 'scorm':
                                  await context.push(
                                    '/scorm', 
                                    extra: {
                                    // 'moduleId': instanceId,
                                      'moduleId': cmid,
                                      'title': activityTitle,
                                    }
                                  );
                                  break;

                                default:
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('La vista directa para "$moduleType" desde calificaciones aún no está configurada.')),
                                  );
                                  break;
                              }
                            // Refrescar al regresar de la ruta
                            if (context.mounted) {
                              ref.invalidate(courseGradesProvider((courseId: widget.courseId, userId: widget.userId)));
                            }
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

final gradesWithSectionProvider =
    FutureProvider.family<List<GradeItem>,
        ({int courseId, int? userId})>((ref, params) async {

  final grades =
      await ref.watch(courseGradesProvider(params).future);

  final modules =
      await ref.watch(courseContentProvider(params.courseId).future);

  // Creamos un mapa para búsqueda rápida
  final moduleMap = {
    for (final m in modules)
      '${m.modname}_${m.instance}': m.sectionName
  };

  for (final grade in grades) {
    if (grade.iteminstance != null) {
      final key = '${grade.itemmodule}_${grade.iteminstance}';
      grade.sectionName = moduleMap[key];
    }
  }

  return grades;
});