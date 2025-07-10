import 'package:flutter/material.dart';
import 'package:flutter_tesis/presentation/widgets/titulos_menu.dart';
import 'package:go_router/go_router.dart';

class SideMenu extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const SideMenu({super.key, required this.scaffoldKey});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int navDrawerIndex=0;

  @override
  Widget build(BuildContext context) {
    final hasNotch= MediaQuery.of(context).viewPadding.top > 35; //cuanto es el pading de top del notch del celular que se este ejecutando
    //si es mayor a 35 tiene un notch grande
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