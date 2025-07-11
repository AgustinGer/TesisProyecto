//import 'package:flutter/cupertino.dart';
import 'package:flutter_tesis/presentation/screens.dart';
import 'package:go_router/go_router.dart';



final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/inicio',
      builder: (context, state) => Inicio(),
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
      path: '/materias',
      builder: (context, state) => Materias(),
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