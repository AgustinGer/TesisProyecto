import 'package:flutter/material.dart';

class Actividades extends StatelessWidget {
  const Actividades({super.key});

  @override
  Widget build(BuildContext context) {
     final colors= Theme.of(context).colorScheme;
      return Scaffold(
      appBar: AppBar(
        
        //backgroundColor: colors.primary,
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
                child: Text('Actividad 1: Algoritmo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),

            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Realize un algoritmo FIFO en C++'),
              ),
            ),

            SizedBox(height: 10),

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
                child: Text('Entrega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),
            
            SizedBox(height: 10),

            

             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10),
               child: Container(
                          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: BorderDirectional(bottom: BorderSide(color: Colors.grey,width: 1)
                  )                
                ),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Text('Fecha de entrega: 24/05/2025, 23:59', ),
                           ),
                           ),
             ),

            SizedBox(height: 10),

            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10),
               child: Container(
                          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: BorderDirectional(bottom: BorderSide(color: Colors.grey,width: 1)
                  )                
                ),
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Text('Tiempo restante: tres dias y 6 horas', ),
                  ),
                ),
             ),

             SizedBox(height: 30),


             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10),
               child: GestureDetector(
                    onTap: () {
                      
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey,
                          width: 2
                        )
                      ),
               
                    child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                        Icon(Icons.cloud_upload_outlined, size: 60,color: Colors.white),
                        SizedBox(height: 8),
                        Text('toque para subir el archivo')
                       ],
                      ),
                    ),
                  ),
             ),

                SizedBox(height: 10),
                
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: (){}, 
                        child: Text('Guardar')),
                /*      ElevatedButton(
                        onPressed: (){}, 
                        child: Text('Guardar')),*/
                    ],
                  ),
                ),

             SizedBox(height: 10),

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
                child: Text('Nota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              ),
            ),
            
            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Calificación: 18'),
              ),
            ),
          ],
        ))// ListInicio(),
    );
  }
}