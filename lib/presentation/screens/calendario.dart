import 'package:flutter/material.dart';
import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';

class Calendario extends StatelessWidget {
  const Calendario({super.key});

  @override
  Widget build(BuildContext context) {
    final colors= Theme.of(context).colorScheme;
    return Scaffold(
       appBar: AppBar(   
     //   backgroundColor: colors.primary,
        title: Text('CALENDARIO'),
        centerTitle: true, 
        //centrar en ios y android
      ),

      body: SafeArea(
        child: ListView.builder(
           itemCount: appMenuItems.length,
           itemBuilder: (context, index){
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Container(
                   decoration: BoxDecoration(
                   border: Border.all(width: 1, color: colors.secondary),
                   ),                  
                    child: Column(
                      children: [

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Computación', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),  
                            ),
                        ),

                        ListTile(                   
                         leading: Icon(Icons.content_paste_go_rounded, color: Colors.black,),
                         title: Text('Entrega de algoritmo en C++'),
                         subtitle: Align(alignment: Alignment.centerRight, child: Text('20/05/2025')),
                        ),
                      ],
                    ),
                    
                  ),
                );
               
                                               
              },
              
          )          
      ),
    );
  }
}