//import 'package:flutter/cupertino.dart';
//import 'package:flutter_tesis/presentation/profesor_screen/assign.dart';

import 'package:flutter_tesis/presentation/profesor_screen/calificar_tarea.dart';
import 'package:flutter_tesis/presentation/profesor_screen/crear_tarea_screen.dart';
import 'package:flutter_tesis/presentation/profesor_screen/lista_notas_estudiantes.dart';
import 'package:flutter_tesis/presentation/profesor_screen/url.dart';
import 'package:flutter_tesis/presentation/profesor_screen/estudiante_tarea.dart';
import 'package:flutter_tesis/presentation/screens.dart';
import 'package:flutter_tesis/presentation/screens/H5P.dart';
import 'package:flutter_tesis/presentation/screens/calificaciones.dart';
import 'package:flutter_tesis/presentation/screens/chat.dart';
import 'package:flutter_tesis/presentation/screens/database.dart';
import 'package:flutter_tesis/presentation/screens/description.dart';
import 'package:flutter_tesis/presentation/screens/discusion.dart';
import 'package:flutter_tesis/presentation/screens/eleccion.dart';
import 'package:flutter_tesis/presentation/screens/foro.dart';
import 'package:flutter_tesis/presentation/screens/glosario.dart';
import 'package:flutter_tesis/presentation/screens/leccion.dart';
import 'package:flutter_tesis/presentation/screens/mensajes.dart';
import 'package:flutter_tesis/presentation/screens/pagina.dart';
import 'package:flutter_tesis/presentation/screens/paquete_ims.dart';
import 'package:flutter_tesis/presentation/screens/paquete_scorm.dart';
import 'package:flutter_tesis/presentation/screens/retroalimentacion.dart';
import 'package:flutter_tesis/presentation/screens/wiki.dart';
import 'package:go_router/go_router.dart';



final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/inicio',
       builder: (context, state) => const Inicio(),
      
    ),
    
// En tu archivo app_router.dart
      GoRoute(
        path: '/actividades/:courseId/:assignmentId',
     //   path: '/actividades/:assignmentId',
        builder: (context, state) {
          final courseId = int.parse(state.pathParameters['courseId']!);
          final assignmentId = int.parse(state.pathParameters['assignmentId']!);
          // Pasamos ambos IDs a la pantalla de Actividades
          return ActividadesScreen(courseId: courseId, assignmentId: assignmentId);
       //   return ActividadesScreen(assignmentId: assignmentId);
        },
      ),

    GoRoute(
      path: '/calendario',
      builder: (context, state) => Calendario(),
      ),

    GoRoute(
      path: '/editar_perfil',
      builder: (context, state) => EditarPerfil(),
      ),

    GoRoute(
      path: '/login',
      builder: (context, state) => Login(),
      ),

    GoRoute(
      path: '/materias/:courseId',
      builder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        return Materias(courseId: courseId);
     },
    ),

    GoRoute(
      path: '/perfil',
      builder: (context, state) => Perfil(),
      ),

    GoRoute(
      path: '/recursos',
      builder: (context, state) {
        // Extrae la lista de archivos que pasamos como 'extra'
        final files = state.extra as List<dynamic>;
        return RecursosScreen(files: files);
      },
    ),

    GoRoute(
      path: '/videos',
      builder: (context, state) {
        // Extrae la URL del video que pasaste como 'extra'
        final params = state.extra as Map<String, dynamic>;
    // 2. Extrae el título y la URL del mapa.
        final title = params['title']!;
        final url = params['url']!;
        // Devuelve la pantalla que mostrará el video
        return VideoScreen(videoTitle: title, videoUrl: url);
      },
    ),


    GoRoute(
        path: '/mensajes',
        builder: (context, state) => const MensajesScreen(),
    ),

      // RUTA ADICIONAL: Para el detalle de un chat específico
    GoRoute(
        path: '/chat-detalle',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return ChatDetalleScreen(
            conversationId: params['conversationId'],
            userName: params['userName'],
            userIdTo: params['userIdTo'],
          );
       },
    ),

    GoRoute(
      path: '/theme',
      name: ThemeChange.name,
      builder: (context, state) => ThemeChange(),
      ),

    GoRoute(
      path: '/description',
      builder: (context, state) {
        final description = state.extra as String;
        return DescriptionScreen(description: description);
      },
    ),
    
    GoRoute(
    path: '/foro/:forumId',
    builder: (context, state) {
    final forumId = int.parse(state.pathParameters['forumId']!);
    return ForumScreen(forumId: forumId);
      },
    ),

    // En tu app_router.dart
    GoRoute(
      // La ruta espera el ID de la discusión
      path: '/foro/discusion/:discussionId',
    //  path: '/discusion/:discussionId',
      builder: (context, state) {
        final discussionId = int.parse(state.pathParameters['discussionId']!);
        return DiscussionDetailScreen(discussionId: discussionId);
      },
    ),

  GoRoute(
    path: '/crear-url/:courseId',
    builder: (context, state) {
      final courseId = int.parse(state.pathParameters['courseId']!);
      final List sections = state.extra as List;
      return CrearUrlScreen(courseId: courseId, sections: sections);
    },
  ),

  GoRoute(
  path: '/estudiante-tarea/:courseId/:assignId',
  builder: (context, state) {
    final courseId = int.parse(state.pathParameters['courseId']!);
    final assignId = int.parse(state.pathParameters['assignId']!);
    // Aquí retornarás tu nuevo widget para el profesor
    return EstudianteTareaScreen(courseId: courseId, assignId: assignId);
  },
),


  GoRoute(
  path: '/crear-tarea/:courseId',
  builder: (context, state) {
    final courseId = int.parse(state.pathParameters['courseId']!);
    final sections = state.extra as List;

    return CrearTareaScreen(
      courseId: courseId,
      sections: sections,
    );
   },
  ),

  GoRoute(
        path: '/mis-notas/:courseId',
        builder: (context, state) {
          final courseId = int.parse(state.pathParameters['courseId']!);
          return MisNotasScreen(courseId: courseId);
        },
      ),

   GoRoute(
      path: '/mis-notas/:courseId/:userId',
      builder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        final userId = int.parse(state.pathParameters['userId']!);

        return MisNotasScreen(
          courseId: courseId,
          userId: userId,
        );
      },
    ),

   GoRoute(
      path: '/calificar-tarea/:courseId/:assignId/:userId',
      builder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        final assignId = int.parse(state.pathParameters['assignId']!);
        final userId = int.parse(state.pathParameters['userId']!);
        
        // Si extra es nulo, ponemos un texto genérico para que no explote
        final String studentName = (state.extra as String?) ?? 'Estudiante';

        return PantallaCalificar(
          courseId: courseId, 
          assignId: assignId, 
          userId: userId,
          studentName: studentName,
        );
      },
    ),


  GoRoute(
      path: '/lista-estudiantes/:courseId',
      builder: (context, state) {
        final courseId = int.parse(state.pathParameters['courseId']!);
        return ListaEstudiantesScreen(courseId: courseId);
      },
    ),

     GoRoute(
          path: '/glosario/:id',
          builder: (context, state) {
            final glossaryId = int.parse(state.pathParameters['id']!);
            final extras = state.extra as Map<String, dynamic>? ?? {};
            
            return GlosarioScreen(
              glossaryInstanceId: glossaryId, 
              title: extras['title'] ?? 'Glosario', 
              moduleContextId: extras['contextId'] ?? 0,
              courseId: extras['courseId'] ?? 0, // <--- NUEVO
              isTeacher: extras['isTeacher'] ?? false,
            );
          },
        ),

      GoRoute(
      path: '/basedatos/:id',
      builder: (context, state) {
        // 1. Obtenemos el ID de la URL
        final dbId = int.parse(state.pathParameters['id']!);
        
        // 2. Obtenemos el mapa de extras (datos que pasas al hacer push)
        final extras = state.extra as Map<String, dynamic>? ?? {};
        
        return DatabaseScreen(
          databaseInstanceId: dbId,
          title: extras['title'] ?? 'Base de Datos',
          moduleId: extras['moduleId'] ?? 0,
          moduleContextId: extras['contextId'] ?? 0, 
          courseId: extras['courseId'] ?? 0,
          isTeacher: extras['isTeacher'] ?? false,
        );
      },
    ),

    // RUTA PARA LA ACTIVIDAD DE ELECCIÓN (CHOICE)
      GoRoute(
        path: '/eleccion',
        builder: (context, state) {
          // 1. Recibimos el objeto 'extra' que enviamos desde Materias.dart
          final Map<String, dynamic> args = state.extra as Map<String, dynamic>;

          // 2. Retornamos la pantalla pasando todos los parámetros
          return EleccionScreen(
            choiceId: args['choiceId'], // ID de la instancia
            moduleId: args['moduleId'], // CMID
            courseId: args['courseId'], // <--- VITAL: ID del Curso para la config
            title: args['title'],       // Título de la actividad
            isTeacher: args['isTeacher'] ?? false,
          );
        },
      ),

    GoRoute(
      path: '/h5p',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return H5PScreen(
          moduleId: extra['moduleId'],
          title: extra['title'],
          // Recibimos el tipo, si no viene (por error), asumimos el moderno
          modName: extra['modName'] ?? 'h5pactivity', 
        );
      },
    ),

    GoRoute(
      path: '/lesson',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return LessonScreen(
          moduleId: extra['moduleId'],
          title: extra['title'],
        );
      },
    ),

    GoRoute(
      path: '/imscp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ImsScreen(
          moduleId: extra['moduleId'],
          title: extra['title'],
        );
      },
    ),

    GoRoute(
      path: '/scorm',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ScormScreen(
          moduleId: extra['moduleId'],
          title: extra['title'],
        );
      },
    ),

  GoRoute(
      path: '/feedback',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return FeedbackScreen(
          moduleId: extra['moduleId'],
          title: extra['title'],
        );
      },
    ),


    // ... rutas ...
    GoRoute(
      path: '/wiki',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return WikiScreen(
          moduleId: extra['moduleId'],
          title: extra['title'],
        );
      },
    ),

 /*  GoRoute(
      path: '/page',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PageScreen(
          moduleId: extra['moduleId'],
          title: extra['title'],
        );
      },
    ),*/

    GoRoute(
      path: '/page_native', // Le pongo _native para diferenciar
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PageScreen(
          pageInstanceId: extra['instanceId'],
          courseId: extra['courseId'],
          title: extra['title'],
        );
      },
    ),

  ],  
);