import 'package:flutter/material.dart';
import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';

class Recursos extends StatelessWidget {
  const Recursos({super.key});

  @override
  Widget build(BuildContext context) {
    final colors= Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        
    //    backgroundColor: colors.primary,
        title: Text('ACTIVIDADES'),
        centerTitle: true, 
        //centrar en ios y android
      ),

      body: SafeArea(
        child: Column(
          children: [
              Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: colors.secondary
                )                
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Unidad recursos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),

              Container(
              decoration: BoxDecoration(
                //border: BorderDirectional(bottom: BorderSide(color: Colors.black,width: 1))
              ) ,
              child: ListView.builder(
               shrinkWrap: true, 
               itemCount: appMenuItems.length,
               itemBuilder: (context, index){
                 return ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                //  trailing: Icon(Icons.verified_outlined, color: Colors.green,),
                  title: Text('Recurso PDF ${index+1}'),
                  );               
               },
              ),
            ),

            Container(
              decoration: BoxDecoration(
                //border: BorderDirectional(bottom: BorderSide(color: Colors.black,width: 1))
              ) ,
              child: ListView.builder(
               shrinkWrap: true, 
               itemCount: appMenuItems.length,
               itemBuilder: (context, index){
                 return ListTile(
                  leading: Icon(Icons.insert_drive_file, color: Colors.green),
                //  trailing: Icon(Icons.verified_outlined, color: Colors.green,),
                  title: Text('Excel ${index+1}'),
                  );                                
               },
              ),
            ),
          ],
      )),
    );
  }
}