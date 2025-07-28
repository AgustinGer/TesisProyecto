import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/provider/user_profile.dart';

// Importa el nuevo provider que acabamos de crear
//import 'package:flutter_tesis/provider/user_profile_provider.dart';

// 1. Cambia a ConsumerWidget
class Perfil extends ConsumerWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. "Observa" el estado del provider del perfil
    final asyncProfile = ref.watch(userProfileProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PERFIL'),
        centerTitle: true,
      ),
      // 3. Usa .when para construir la UI según el estado (cargando, error, éxito)
      body: asyncProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) {
          // 4. Si hay datos, extrae la información y úsala en tu UI
          final String fullName = user['fullname'] ?? 'Sin nombre';
          final String email = user['email'] ?? 'Sin email';
          final String description = user['description'] ?? 'Sin descripción.';
          // La URL de la imagen del perfil que viene de Moodle
          final String imageUrl = user['profileimageurl'] ?? '';
          final String interests = user['interests'] ?? '';
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty 
                          ? const Icon(Icons.person, size: 80) 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Divider(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Descripción',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Usamos el widget Html para mostrar la descripción con su formato
                  Html(data: description),

                  const SizedBox(height: 8),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Intereses',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),

                  if (interests.isNotEmpty)
                  Wrap(
                    spacing: 8.0, // Espacio horizontal entre cada chip
                    runSpacing: 4.0, // Espacio vertical entre las filas
                    children: interests.split(',').map((interest) {
                      // 3. Creamos un Chip para cada interés
                      return Chip(
                        label: Text(interest.trim(),style: TextStyle(color: Colors.white),), // .trim() quita espacios extra
                        backgroundColor: colors.primary,
                        shape: const StadiumBorder(),
                      );
                    }).toList(),
                  )
                else
                  const Text('No se han especificado intereses.'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}










/*
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
}*/