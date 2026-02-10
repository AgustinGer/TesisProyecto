import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/presentation/screens/agregar_basedatos.dart';
import 'package:flutter_tesis/provider/database_provider.dart';
//import 'package:intl/intl.dart'; // Agrega intl en pubspec.yaml para formatear fechas


class DatabaseScreen extends ConsumerWidget {
  final int databaseInstanceId; // El ID de la instancia (module['instance'])
  final int moduleId; // El CMID (module['id']) - por si quieres agregar comentarios/calificación luego
  final String title;

  const DatabaseScreen({
    super.key,
    required this.databaseInstanceId,
    required this.moduleId,
    required this.title,
  });

  /*String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }*/

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(databaseEntriesProvider(databaseInstanceId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // Botón para agregar (pendiente de implementar lógica compleja)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgregarBaseDatosScreen(databaseId: databaseInstanceId),
            ),
          );

          if (result == true) {
            // Recargar la lista de entradas si se guardó una nueva
            ref.invalidate(databaseEntriesProvider(databaseInstanceId));
          }
        },
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No hay registros en esta base de datos.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera: Autor y Fecha
                     /* Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: const Icon(Icons.person, color: Colors.indigo),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.userFullName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatDate(entry.timeCreated),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),*/
                      const Divider(height: 20),

                      // Contenido de los campos
                     // ...entry.contents.map((content) {
                     /*...entry.fields.entries.map((field) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200)
                          ),
                         
                          child: Html(
                            data: content.content, // Renderizamos el valor como HTML
                            style: {
                              "body": Style(margin: Margins.zero, fontSize: FontSize(14)),
                              "img": Style(width: Width(100, Unit.percent)), // Ajustar imágenes


                            },
                          ),
                        );                      
                      }),*/
                      // Contenido de los campos (YA MAPEADOS)
                      ...entry.fields.entries.map((field) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.key, // nombre del campo
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Html(
                                data: field.value, // valor ya traducido (texto real)
                                style: {
                                  "body": Style(
                                    margin: Margins.zero,
                                    fontSize: FontSize(14),
                                  ),
                                  "img": Style(
                                    width: Width(100, Unit.percent),
                                  ),
                                },
                              ),
                            ],
                          ),
                        );
                      }),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}