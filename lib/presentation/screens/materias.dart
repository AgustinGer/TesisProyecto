import 'package:flutter/material.dart';
import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';
import 'package:go_router/go_router.dart';

class Materias extends StatelessWidget {
  const Materias({super.key});

  @override
  Widget build(BuildContext context) {
  // final colors= Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
      //  backgroundColor: colors.primary,
        title: Text('Programacion',style: TextStyle(color: Colors.white)),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: 
      NavegacionMaterias()// ListInicio(),
    );
  }
}

class NavegacionMaterias extends StatelessWidget {
  const NavegacionMaterias({
    super.key,
  });

  final int countActividad=0;
  @override
  Widget build(BuildContext context) {
       final colors= Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column( 
            children: [
            Image(image: NetworkImage('https://img.freepik.com/vector-premium/logo-nombre-universidad-logo-empresa-llamada-universidad_516670-732.jpg'),height:200, width: double.infinity,fit: BoxFit.cover,), 
            
            SizedBox(height: 30),
            
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
            child:ListTile(
            leading: Icon(Icons.bookmark_sharp, color: Colors.green),
            // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
            title: Text('INFORMACION CURSO'),
            ),
          ),
            
            SizedBox(height: 30),
            Text('NO se ha proporcionado informacion del curso actualmente'), 
            SizedBox(height: 30), 
        
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                // color: Colors.white,
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
            child:ListTile(
            leading: Icon(Icons.cases_outlined, color: Colors.blue),
            title: Text('RECURSOS'),
            ),                     
          ),
        
              ListTile(
              leading: Icon(Icons.ios_share  , color: Colors.grey),
              subtitle: Text('Matrial de apoyo'),
              onTap: () {
                context.push('/recursos');
               },
              ),  
            
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
                
        
                child:ListTile(
                leading: Icon(Icons.collections_sharp, color: Colors.red),
                // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
                title: Text('ACTIVIDADES'),

                ),                     
                // chi: Center(child: Text('hola')),
              ),
        
              
         
        
            SizedBox(height: 10), 

          //  Text('actividad 1'),

            Container(
              decoration: BoxDecoration(
                border: BorderDirectional(bottom: BorderSide(color: Colors.black,width: 1))
              ) ,
              child: ListView.builder(
               shrinkWrap: true, 
               itemCount: appMenuItems.length,
               itemBuilder: (context, index){
                 return ListTile(
                  leading: Icon(Icons.description_rounded, color: Colors.yellow),
                  trailing: Icon(Icons.verified_outlined, color: Colors.green,),
                  subtitle: Text('Actividad ${index+1}'),
                  onTap: () {
                     context.push('/actividades');
                   },
                  );               
               },
              ),
            ),
        
            Container(
              //height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                // color: Colors.white,
                 borderRadius: BorderRadius.circular(5),
                 border: Border.all(
                    color: colors.secondary, // Color del borde
                    width: 1.0,         // Grosor del borde
               ),
              ),
        
                child:ListTile(
                leading: Icon(Icons.video_file, color: Colors.brown),
                // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
                title: Text('VIDEOS'),
                ),                     
              ),
        
              

              ListTile(
              leading: Icon(Icons.video_call_sharp  , color: Colors.grey),
              // trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
              subtitle: Text('Videos de apoyo'),
              onTap: () {
                context.push('/videos');
               },
              ),
              SizedBox(height: 10),             
            ],
          ),
        ),
      ));
  }
}