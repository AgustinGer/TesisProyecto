//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/config/app_router.dart';
//import 'package:flutter_tesis/presentation/screens/login.dart';
import 'package:flutter_tesis/provider/theme_provider.dart';
//import 'package:flutter_tesis/presentation/screens/editar_perfil.dart';
//import 'package:flutter_tesis/presentation/screens/calendario.dart';
//import 'package:flutter_tesis/presentation/screens/perfil.dart';
//import 'package:flutter_tesis/presentation/screens/actividades.dart';
//import 'package:flutter_tesis/presentation/screens/recursos.dart';
//import 'package:flutter_tesis/presentation/screens/videos.dart';
//import 'package:flutter_tesis/presentation/screens/inicio.dart';
//import 'package:flutter_tesis/presentation/screens/materias.dart';
//import 'package:flutter_tesis/presentation/screens/login.dart';
import 'package:flutter_tesis/theme/app_temas.dart';

//final container = ProviderContainer();
void main(){
//  HttpOverrides.global = MyHttpOverrides();
 

  runApp(
    ProviderScope(child: MyApp())
      /*UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),*/
  );
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final isDarkMode = ref.watch(isDarkModeProvider);
    final selectedColor = ref.watch(selectColorProvider);
   
    
    return MaterialApp.router(
     // title: 'Yes o no',
     routerConfig: appRouter,
     debugShowCheckedModeBanner: false,
     theme: AppTemas(selectColor: selectedColor, isdarkmode: isDarkMode).theme(),
    //  theme: AppTemas(selectColor: 1).theme(),
    //  home: const Login()
    //   home: const Inicio()
         //home: const EditarPerfil(),
      // colores
      /*Scaffold(
        appBar: AppBar(
          title: const Text('Material App Bar'),
        ),
        body: Center(
          child: FilledButton.tonal(onPressed: (){}, child: const Text('click me')),
        ),
      ),*/
    );
  }
}