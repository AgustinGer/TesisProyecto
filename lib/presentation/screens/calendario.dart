import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/calendar_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';


class Calendario extends ConsumerWidget {
  const Calendario ({super.key});

  // Función para formatear la fecha
  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'Fecha no definida';
    initializeDateFormatting('es');
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.yMd('es').format(date); // Formato: 20/05/2025
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("CALENDARIO"),
        centerTitle: true,
      ),
      body: asyncEvents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No tienes eventos próximos.'));
          }
          // Si hay datos, construimos la lista de eventos
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(event: event, formatTimestamp: _formatTimestamp);
            },
          );
        },
      ),
    );
  }
}

// Widget para mostrar una sola tarjeta de evento
class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final String Function(int) formatTimestamp;

  const _EventCard({required this.event, required this.formatTimestamp});

  @override
  Widget build(BuildContext context) {
    final colors= Theme.of(context).colorScheme;
    final String courseName = event['course']['fullname'] ?? 'General';
    //final String eventName = event['name'] ?? 'Evento sin nombre';
    final String eventName = (event['name'] as String? ?? 'Evento sin nombre')
    .replaceAll(' está en fecha de entrega', '');
    final int eventDate = event['timestart'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: colors.secondary.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // Verificamos que el evento sea una tarea ('assign')
          if (event['modulename'] == 'assign') {
            
            // --- ESTA ES LA PARTE IMPORTANTE ---
            // Extraemos ambos IDs directamente del evento del calendario
            final int courseId = event['course']['id'];
            final int assignmentId = event['instance'];
            
            // Navegamos a la ruta que espera AMBOS IDs
            context.push('/actividades/$courseId/$assignmentId');

          } else {
            // Opcional: manejar otros tipos de eventos si quieres
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Este evento no es una tarea.')),
            );
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(courseName, style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_go_rounded, color: Colors.black),
              title: Text(eventName),
              subtitle: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatTimestamp(eventDate),
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    
    
    
    /*Padding(
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
                    child: Text(courseName, style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),  
                    ),
                ),

                ListTile(                   
                  leading: Icon(Icons.content_paste_go_rounded, color: Colors.black,),
                  title: Text(eventName),
                  subtitle: Align(alignment: Alignment.centerRight, child: Text(formatTimestamp(eventDate),
                          style: const TextStyle(color: Colors.black54),),),
                  onTap: () {
                    
                    if (event['modulename'] == 'assign') {
                  // Extraemos los IDs necesarios
                  final int courseId = event['course']['id'];
                  final int assignmentId = event['instance']; // El ID de la tarea en los eventos es 'instance'
                  
                  // Navegamos a la ruta de actividades que ya tienes configurada
                  context.push('/actividades/$courseId/$assignmentId');
                  }
                },
              ),
            ],
          ),
          
        ),
       ); */  
    
    /*Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.assignment_outlined, color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    eventName,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatTimestamp(eventDate),
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );*/
  }
}

/*class Calendario extends StatelessWidget {
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
}*/