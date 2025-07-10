import 'package:flutter/material.dart';

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    //final colors= Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(   
     //   backgroundColor: colors.primary,
        title: Text('PERFIL'),
        centerTitle: true, 
        //centrar en ios y android
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Center(
                child: Container(             
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                   image:DecorationImage(image: NetworkImage('https://img.freepik.com/vector-premium/logo-nombre-universidad-logo-empresa-llamada-universidad_516670-732.jpg')),
                  ),
                           //   child: Image(image: NetworkImage('url')),
                ),
              ),
          

              Text('GEOVANNY AGUSTIN LUNA GER',textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),

              SizedBox(height: 15),

              Text('geovanny.luna@epn.edu.ec', textAlign: TextAlign.center,style: TextStyle(color: Colors.black)),
               
              SizedBox(height: 20),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Descripcion', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black))),
              
              Text('Soy una persona tranquila, que disfruta de actividades relajantes. Mis pasatiempos son los juegos de mesa porque estimulan la estrategia y la colaboración, mientras que el tenis y los videojuegos me ofrecen una forma de liberar energía y de relajarme.', textAlign: TextAlign.justify ),
             
            ],
          ),
        )),
    );
  }
}