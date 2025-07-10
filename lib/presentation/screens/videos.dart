import 'package:flutter/material.dart';
import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';

class Videos extends StatelessWidget {
  const Videos({super.key});

  @override
  Widget build(BuildContext context) {
  //   final colors= Theme.of(context).colorScheme;
    return Scaffold(
       appBar: AppBar(   
   //     backgroundColor: colors.primary,
        title: Text('VIDEOS'),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: SafeArea(
        child: Column(
          children: [
           SizedBox(height: 10),

           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 10),
             child: ListView.builder(
              shrinkWrap: true, 
              itemCount: appMenuItems.length,
              itemBuilder: (context, index){
                return Container(
                 decoration: BoxDecoration(
                 border: BorderDirectional(bottom: BorderSide(color: Colors.grey,width: 1))
                 ),
                  child: Column(          
                    children: [
                     Align(alignment: Alignment.centerLeft,
                      child: Text('Video ${index+1}:',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                      ),
                     Align(alignment: Alignment.centerLeft,
                      child: Text('https://www.youtube.com/watch?v=hT_nvWreIhg',style: TextStyle(fontSize: 14))
                      ),
             
                      SizedBox(height: 10),
                    ],
                  ),
                );                               
              },
             ),
           ),
          ],

        ))
    );
  }
}