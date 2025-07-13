import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_tesis/listas/pruebas/listas_pruebas.dart';
import 'package:flutter_tesis/models/course.dart';
import 'package:flutter_tesis/presentation/widgets/side_menu.dart';
import 'package:flutter_tesis/provider/course_provider.dart';
import 'package:go_router/go_router.dart';

class Inicio extends ConsumerWidget {
  
  // 2. Ya no necesita recibir `token` ni `email` en el constructor.
  const Inicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    final scaffoldKey = GlobalKey<ScaffoldState>();

    // 3. La llamada al provider ahora es simple. No se le pasan parámetros.
    final asyncCourses = ref.watch(coursesProvider);
    
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Mis Cursos'),
        centerTitle: true,
      ),
      endDrawer: SideMenu(scaffoldKey: scaffoldKey),
      
      // 4. El resto de la lógica para mostrar los datos es exactamente la misma.
      //    .when() se encarga de todo.
      body: asyncCourses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar los cursos: $err')),
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text('No estás inscrito en ningún curso.'));
          }
          // Si hay datos, construimos la lista
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseListItem(course: course);
            },
          );
        },
      ),
    );
  }
}

// Este widget para mostrar cada item de la lista ya estaba bien. No necesita cambios.
class _CourseListItem extends StatelessWidget {
  const _CourseListItem({required this.course});
  final Course course;

  @override

  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
     //selectedTileColor: Theme.of(context).colorScheme.primary,
     //selected: true,
  //   leading: Icon(menuItem.icon, color: colors.primary),
     leading: const Icon(Icons.school_outlined, color: Colors.blueGrey),
     trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
   //  title: Text(menuItem.title),
   //  subtitle: Text(menuItem.subtittle),
     title: Text(course.fullName),
     subtitle: Text(course.summary.trim(), maxLines: 2, overflow: TextOverflow.ellipsis),
     onTap: (){
       context.push('/materias/${course.id}');
     },
    );
  }
}

/*class Inicio extends ConsumerWidget {
  final String token;
  final String email;
  
  const Inicio({super.key, required this.token, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) { 
    final scaffoldKey= GlobalKey<ScaffoldState>();
     final asyncCourses = ref.watch(coursesProvider({'token': token, 'email': email}));
     
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
      endDrawer: SideMenu(scaffoldKey: scaffoldKey),
     // body: ListInicio(),
      body: asyncCourses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text('No estás inscrito en ningún curso.'));
          }
          // Si hay datos, construimos la lista
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _ListCurso(course: course);
            },
          );
        },
      ),
    );
  }
}

class _ListCurso extends StatelessWidget {
  const _ListCurso({
    required this.course
  });

  final Course course;

  @override

  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
     //selectedTileColor: Theme.of(context).colorScheme.primary,
     //selected: true,
  //   leading: Icon(menuItem.icon, color: colors.primary),
     leading: const Icon(Icons.school_outlined, color: Colors.blueGrey),
     trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.primary),
   //  title: Text(menuItem.title),
   //  subtitle: Text(menuItem.subtittle),
     title: Text(course.fullName),
     subtitle: Text(course.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
     onTap: (){
       context.push('/materias/${course.id}');
     },
    );
  }
}*/
 /* Widget build(BuildContext context) {
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
}*/

/*class _CustomListInicio extends StatelessWidget {
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
}*/