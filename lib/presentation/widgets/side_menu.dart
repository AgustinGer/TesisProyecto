import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/presentation/widgets/titulos_menu.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/user_profile.dart';
import 'package:go_router/go_router.dart';

class SideMenu extends ConsumerStatefulWidget{
  final GlobalKey<ScaffoldState> scaffoldKey;
  const SideMenu({super.key, required this.scaffoldKey});

  @override
  ConsumerState<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends ConsumerState<SideMenu> {
  int navDrawerIndex=0;

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(userProfileProvider);
    final userRole = ref.watch(userRoleProvider);
    final hasNotch= MediaQuery.of(context).viewPadding.top > 35; //cuanto es el pading de top del notch del celular que se este ejecutando
    //si es mayor a 35 tiene un notch grande

      String roleName;
      Color roleColor;

      switch (userRole) {
        case UserRole.admin:
          roleName = 'Administrador';
          roleColor = Colors.red.shade700;
          break;
        case UserRole.profesor:
          roleName = 'Profesor';
          roleColor = Colors.indigo;
          break;
        case UserRole.estudiante:
          roleName = 'Estudiante';
          roleColor = Colors.grey.shade600;
          break;
      }
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
                          Text(
                            roleName,
                            style: TextStyle(
                              fontSize: 14, 
                              color: roleColor, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
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

        
     /*   NavigationDrawerDestination(
          icon: const Icon(Icons.add), 
          label: const Text('otra pantalla')
        ),*/
        
      ]);
  }
}