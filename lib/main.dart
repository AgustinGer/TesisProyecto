//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/config/app_router.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
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
import 'package:go_router/go_router.dart';

void main(){
  runApp(
    ProviderScope(child: MyApp())
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

// --- PANTALLA DE CONTROL INICIAL (SPLASH SCREEN) ---
// Esta pantalla decide a dónde enviar al usuario
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

 Future<void> _verificarSesion() async {
    // 1. Le damos 1 segundo de retraso para que se vea el logo
    await Future.delayed(const Duration(seconds: 1)); 
    
    // 2. TRABAJO ASÍNCRONO: Leemos el disco duro (SharedPreferences)
    final tieneSesion = await checkSavedSession(ref);
    
    // 3. VERIFICACIÓN DE SEGURIDAD OBLIGATORIA
    // Ponemos esto justo antes de navegar, después de que toda la "espera" terminó.
    if (!mounted) return;

    // 4. NAVEGACIÓN SEGURA
    if (tieneSesion) {
      context.go('/inicio'); // Sesión restaurada, entra directo
    } else {
      context.go('/login');  // No hay sesión, ve al login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Puedes poner tu logo aquí para que se vea como app profesional
            Container(
              height: 150,
              width: 150,
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/imagenes/logo.png'), fit: BoxFit.fill),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(), // Cargando suavemente
          ],
        ),
      ),
    );
  }
}