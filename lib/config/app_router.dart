//import 'package:flutter/cupertino.dart';
import 'package:flutter_tesis/presentation/screens.dart';
import 'package:go_router/go_router.dart';



final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/inicio',
      /*builder: (context, state) {
       final params = state.extra as Map<String, dynamic>;
       final token = params['token']!;
       final email = params['email']!;*/
       builder: (context, state) => const Inicio(),
       //return Inicio(token: token, email: email);
      
    ),
    
    GoRoute(
      path: '/actividades',
      builder: (context, state) => Actividades(),
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
      // 1. La ruta ahora espera un parámetro 'courseId'
      path: '/materias/:courseId',
      builder: (context, state) {
        // 2. Extraemos el ID de los parámetros de la ruta
        final courseId = int.parse(state.pathParameters['courseId']!);
        
        // 3. Pasamos el ID a la pantalla de Materias
        return Materias(courseId: courseId);
     },
    ),

    GoRoute(
      path: '/perfil',
      builder: (context, state) => Perfil(),
      ),

    GoRoute(
      path: '/recursos',
      builder: (context, state) => Recursos(),
      ),

    GoRoute(
      path: '/videos',
      builder: (context, state) => Videos(),
      ),
    
    GoRoute(
      path: '/theme',
      name: ThemeChange.name,
      builder: (context, state) => ThemeChange(),
      ),
  ],  
);