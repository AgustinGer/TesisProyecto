import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/presentation/calificar_modal.dart';
import 'package:flutter_tesis/presentation/screens/agregar_glosario.dart';
import 'package:flutter_tesis/presentation/widgets/comentarios_model.dart';
import 'package:flutter_tesis/presentation/widgets/glosario_file.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/glosario_provider.dart';
import 'package:flutter_tesis/provider/teacher_provider.dart';


class GlosarioScreen extends ConsumerWidget {
  final int glossaryInstanceId;
  final String title;

  final bool isTeacher;

  final int courseId; // <--- Nuevo campo
  final int moduleContextId;

  const GlosarioScreen({
    super.key, 
    required this.glossaryInstanceId,
    required this.title, // Pasamos el título para ponerlo en el AppBar

    required this.isTeacher,

    required this.courseId,
    required this.moduleContextId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el provider
    final entriesAsync = ref.watch(glossaryEntriesProvider(glossaryInstanceId));

    final configAsync = ref.watch(glossaryConfigProvider((courseId: courseId, glossaryId: glossaryInstanceId)));
   
   // 3. NUEVO: Cargamos la lista de IDs de los profesores
  final teachersListAsync = ref.watch(courseTeachersProvider(courseId));

  // 4. Tu ID (para no calificarte a ti mismo)
  final myUserId = ref.read(userIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

     floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.indigo,
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () async {
        // Navegamos y esperamos respuesta para refrescar
        // Si usas Navigator normal:
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgregarGlosarioScreen(glossaryId: glossaryInstanceId)
          ),
        );

        if (result == true) {
          // Si guardó con éxito, refrescamos la lista
          ref.invalidate(glossaryEntriesProvider(glossaryInstanceId));
        }
      },
    ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $err'),
        )),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No hay términos en este glosario.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.translate, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    entry.concept,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Por: ${entry.userFullName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        )
                      ),

                     child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. La Definición HTML
                        Html(
                          data: entry.definition,
                          style: {
                            "body": Style(margin: Margins.zero, fontSize: FontSize(15)),
                          },
                        ),

                        // 2. LOGICA PARA MOSTRAR ARCHIVOS
                        if (entry.attachments.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          const Divider(),
                          const Text(
                            'Archivos adjuntos:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 5),
                          // Aquí usamos el widget que creamos en el paso 2
                          ...entry.attachments.map((file) => GlossaryFileWidget(file: file)),
                        ]
                      ],
                    ),
                   ),

                  // 2. DIVISOR (Ahora está fuera del Container, es válido)
                          const Divider(height: 1),

                          // 3. BOTÓN COMENTARIOS
                       /*   Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.comment_outlined, size: 18),
                                  label: const Text('Comentarios'),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => ComentariosModal(
                                        contextId: moduleContextId,
                                        entryId: entry.id,
                                        entryTitle: entry.concept,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),*/

                    configAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_,__) => const SizedBox.shrink(),
                      //data: (allowComments) {
                      data: (config) {
                        final showComments = config.allowComments;

                        final List<int> teacherIds = teachersListAsync.value ?? [];
                        final bool isAuthorTeacher = teacherIds.contains(entry.userId);
                        final bool isMe = (entry.userId == myUserId);

                        // 1. ¿Mostrar botón CALIFICAR?
                        // - Soy profesor (isTeacher)
                        // - Moodle tiene ratings activos (config.ratingsEnabled)
                        // - El autor NO es profesor (!isAuthorTeacher)
                        // - El autor NO soy yo (!isMe)
                        final bool showRating = isTeacher && 
                                                config.ratingsEnabled && 
                                                !isAuthorTeacher && 
                                                !isMe;
                        // SI NO ESTÁN PERMITIDOS, NO MOSTRAMOS NADA
                       // if (!allowComments) return const SizedBox.shrink();
                       if (!showComments && !showRating) return const SizedBox.shrink();
                        // SI SÍ ESTÁN PERMITIDOS, MOSTRAMOS EL DIVIDER Y EL BOTÓN
                        return Column(
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [

                                //if (isTeacher) 
                                if (showRating)
                                      TextButton.icon(
                                        icon: const Icon(Icons.star_rate_rounded, size: 18, color: Colors.orange),
                                        label: const Text('Calificar', style: TextStyle(color: Colors.orange)),
                                        onPressed: () {
                                          print('DEBUG: Abriendo modal con Scale ID: ${config.scaleId}');
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true, // Importante para el teclado
                                            builder: (context) => CalificarModal(
                                              contextId: moduleContextId,
                                              entryId: entry.id,
                                              ratedUserId: entry.userId, // Usamos el ID del alumno que añadimos al modelo
                                              studentName: entry.userFullName,
                                              scaleId: config.scaleId,
                                            ),
                                          );
                                        },
                                      ),

                                    const SizedBox(width: 8),

                                  TextButton.icon(
                                    icon: const Icon(Icons.comment_outlined, size: 18),
                                    label: const Text('Comentarios'),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => ComentariosModal(
                                          contextId: moduleContextId,
                                          entryId: entry.id,
                                          entryTitle: entry.concept,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    ),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}