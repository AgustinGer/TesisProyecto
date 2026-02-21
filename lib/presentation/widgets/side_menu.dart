import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/widgets/titulos_menu.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
//import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/user_profile.dart';
import 'package:flutter_tesis/provider/user_role_provider.dart';
//import 'package:flutter_tesis/provider/user_role_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';


/*

class SideMenu extends ConsumerStatefulWidget{
  final GlobalKey<ScaffoldState> scaffoldKey;
  //final int courseId;
  const SideMenu({super.key, required this.scaffoldKey});

  @override
  ConsumerState<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends ConsumerState<SideMenu> {
  int navDrawerIndex=0;

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(userProfileProvider);
    //final userRole = ref.watch(userRoleProvider);
    
   // final userRoleAsync = ref.watch(userRole(courseId));
    final hasNotch= MediaQuery.of(context).viewPadding.top > 35; //cuanto es el pading de top del notch del celular que se este ejecutando
    //si es mayor a 35 tiene un notch grande

      //String roleName;
      //Color roleColor;

    return NavigationDrawer(
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) {
        setState(() {
          navDrawerIndex=value;
        });

        final tituloMenu= appTitulosMenu[value];
        context.push(tituloMenu.link);
        widget.scaffoldKey.currentState?.closeDrawer();
      },
      children:[

      asyncProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('Error al cargar perfil'),
          data: (user) {
            final String fullName = user['fullname'] ?? 'Usuario';
         //   final String email = user['email'] ?? 'Sin email';
            final String imageUrl = user['profileimageurl'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                  children: [
                  CircleAvatar(
                      radius: 30,
                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Alinea al inicio
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          // --- ESTE ES EL NUEVO TEXTO DEL ROL ---
                        ],
                      ),                
                    ),
                ],
              ),
            );
          },
        ),

        Padding(
           padding: EdgeInsets.fromLTRB(28,10,16,10),
          child: Divider(),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(20, hasNotch ? 0 : 20,16,10),
          child: Text('Main'),
        ),

        ...appTitulosMenu.sublist(0,3).map((item) => NavigationDrawerDestination(
          icon: Icon(item.iconTitulo), 
          label: Text(item.tituloMenu),
         ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(28,10,16,10),
          child: Divider(),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28,10,16,10),
          child: Text('More options'),
        ),

        ...appTitulosMenu.sublist(3).map((item) => NavigationDrawerDestination(
          icon: Icon(item.iconTitulo), 
          label: Text(item.tituloMenu),
         ),
        ),
      ]);
  }
}*/

class SideMenu extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  //final int courseId;
  const SideMenu({super.key, required this.scaffoldKey});

  @override
  ConsumerState<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends ConsumerState<SideMenu> {
  int navDrawerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(userProfileProvider);
    final hasNotch = MediaQuery.of(context).viewPadding.top > 35; 

    return NavigationDrawer(
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) async {
        setState(() {
          navDrawerIndex = value;
        });

        final tituloMenu = appTitulosMenu[value];

        // ---------------------------------------------------------
        // LÓGICA INTELIGENTE: DETECTAR "CERRAR SESIÓN"
        // ---------------------------------------------------------
        if (tituloMenu.link == '/login') {
          // 1. Cerramos el menú lateral visualmente
          widget.scaffoldKey.currentState?.closeDrawer();

// 2. PRIMERO BORRAMOS EL DISCO DURO (El trabajo asíncrono)
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // 3. VERIFICACIÓN DE SEGURIDAD OBLIGATORIA EN FLUTTER
          // Si el menú se cerró o se destruyó durante el 'await', detenemos el proceso aquí.
          if (!context.mounted) return;
          // 2. Limpiamos TODA la caché de Riverpod del usuario actual
          ref.invalidate(authTokenProvider);
          ref.invalidate(userIdProvider);
          ref.invalidate(userProfileProvider);

          ref.invalidate(isAdminProvider); 
          ref.invalidate(userCourseRoleProvider);
          ref.invalidate(userRole);
          // 3. Destruimos el historial y volvemos al login de cero

          context.go('/login');

        } else {
          // Si es cualquier otra opción (Perfil, Calendario, Temas), navega normal
          context.push(tituloMenu.link);
          widget.scaffoldKey.currentState?.closeDrawer();
        }
      },
      children: [
        
        asyncProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('Error al cargar perfil'),
          data: (user) {
            final String fullName = user['fullname'] ?? 'Usuario';
            final String imageUrl = user['profileimageurl'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
          child: Divider(),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(20, hasNotch ? 0 : 20, 16, 10),
          child: const Text('Main'),
        ),

        ...appTitulosMenu.sublist(0, 3).map((item) => NavigationDrawerDestination(
              icon: Icon(item.iconTitulo),
              label: Text(item.tituloMenu),
            )),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
          child: Divider(),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
          child: Text('More options'),
        ),

        ...appTitulosMenu.sublist(3).map((item) {
          // Detectamos si es el botón de Cerrar Sesión para ponerlo rojito
          final isLogout = item.link == '/login';
          
          return NavigationDrawerDestination(
            icon: Icon(item.iconTitulo, color: isLogout ? Colors.red : null),
            label: Text(
              item.tituloMenu, 
              style: TextStyle(
                color: isLogout ? Colors.red : null,
                fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ],
    );
  }
}