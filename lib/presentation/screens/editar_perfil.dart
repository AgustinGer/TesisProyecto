import 'package:flutter/material.dart';
import 'package:flutter_tesis/presentation/shared/editar_descripcion.dart';


class EditarPerfil extends StatelessWidget {
  const EditarPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final colors= Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(   
    //    backgroundColor: colors.primary,
        title: Text('EDITAR PERFIL'),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: SafeArea(
        child:Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView(
            children: [
                
                SizedBox(height: 10),

                Align(
                alignment: Alignment.centerLeft,
                child: Text('Descripcion', style: TextStyle(fontWeight: FontWeight.bold,color: colors.primary))),

                SizedBox(height: 10),
                EditarDescripcion(),

                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: (){}, 
                        child: Text('Editar')),
                      ElevatedButton(
                        onPressed: (){}, 
                        child: Text('Guardar')),
                  /*  ElevatedButton(
                        onPressed: (){}, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary, 
                          foregroundColor: Colors.white, 
                        ),
                        child: Text('Guardar'))*/
                    ],
                  ),
                ),

                SizedBox(height: 10),

                Container(
                  height: 1,
                  color: Colors.black,
                ),

                SizedBox(height: 10),

                Align(
                alignment: Alignment.centerLeft,
                child: Text('Intereses', style: TextStyle(fontWeight: FontWeight.bold,color: colors.primary))),
                  
                SizedBox(height: 10),
                EditarDescripcion(),
                
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: (){}, 
                        child: Text('Editar')),
                      ElevatedButton(
                        onPressed: (){}, 
                        child: Text('Guardar')),
                    ],
                  ),
                ),
                
                SizedBox(height: 10),

                Container(
                  height: 1,
                  color: Colors.black,
                ),

                SizedBox(height: 10),

                Align(
                alignment: Alignment.centerLeft,
                child: Text('Imagen Usuario', style: TextStyle(fontWeight: FontWeight.bold,color: colors.primary))),
              
                SizedBox(height: 10),

                GestureDetector(
                  onTap: () {
                    
                  },
                  child: Container(
                    height: 200,
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
                      Text('toca para cambiar de imagen')
                     ],
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

          ],
         ),
        ) 
      ),
    );
  }
}