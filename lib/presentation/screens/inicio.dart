import 'package:flutter/material.dart';
import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';
import 'package:flutter_tesis/presentation/widgets/side_menu.dart';
import 'package:go_router/go_router.dart';

class Inicio extends StatelessWidget {
  
  
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    //final colors= Theme.of(context).colorScheme;
    
    final scaffoldKey= GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        //backgroundColor: colors.secondary,
        leading: Padding(    
          padding: const EdgeInsets.symmetric(horizontal: 8),       
          child: CircleAvatar(          
            backgroundImage: NetworkImage('https://img.freepik.com/vector-premium/logo-nombre-universidad-logo-empresa-llamada-universidad_516670-732.jpg'),
          ),
        ),
        title: Text('Udemy Lab'),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: ListInicio(),
      endDrawer: SideMenu(scaffoldKey: scaffoldKey),
     // body: _ChatView(),
    );
  }
}

class ListInicio extends StatelessWidget {
  const ListInicio({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: ListView.builder(
            itemCount: appMenuItems.length,
            itemBuilder: (context, index){
            final menuItem = appMenuItems[index];
            
              return _CustomListInicio(menuItem: menuItem);
            
            })   
                
      ),
    );
  }
}

class _CustomListInicio extends StatelessWidget {
  const _CustomListInicio({
    //super.key,
    required this.menuItem,
  });

  final MenuItem menuItem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
     //selectedTileColor: Theme.of(context).colorScheme.primary,
     //selected: true,
     leading: Icon(menuItem.icon, color: colors.primary),
     trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
     title: Text(menuItem.title),
     subtitle: Text(menuItem.subtittle),
     onTap: (){
       context.push('/materias');
     },
    );
   
  }
}