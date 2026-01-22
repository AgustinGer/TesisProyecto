//import 'package:flutter/cupertino.dart';
import 'package:flutter_tesis/presentation/profesor_screen/assign.dart';
import 'package:flutter_tesis/presentation/profesor_screen/url.dart';
import 'package:flutter_tesis/presentation/screens.dart';
import 'package:flutter_tesis/presentation/screens/description.dart';
import 'package:flutter_tesis/presentation/screens/discusion.dart';
import 'package:flutter_tesis/presentation/screens/foro.dart';
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
    
   /* GoRoute(
      path: '/videos',
      builder: (context, state) => Videos(),
      ),*/
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
  path: '/crear-tarea/:courseId',
  builder: (context, state) {
    // Extraemos el ID del curso de la URL
    final courseId = int.parse(state.pathParameters['courseId']!);
    
    // Extraemos la lista de secciones enviada mediante 'extra'
    final List sections = state.extra as List;
    
    return CrearTareaScreen(
      courseId: courseId, 
      sections: sections
    );
   },
  ) ,

  GoRoute(
    path: '/crear-url/:courseId',
    builder: (context, state) {
      final courseId = int.parse(state.pathParameters['courseId']!);
      final List sections = state.extra as List;
      return CrearUrlScreen(courseId: courseId, sections: sections);
    },
  ),

  ],  
);