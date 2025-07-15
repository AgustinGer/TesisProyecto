// Crea un nuevo archivo screens/discussion_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tesis/provider/discussion_post_provider.dart';


class DiscussionDetailScreen extends ConsumerWidget {
  final int discussionId;
  const DiscussionDetailScreen({super.key, required this.discussionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(discussionPostsProvider(discussionId));

    return Scaffold(
      appBar: AppBar(
        // El título podría ser el asunto de la discusión
        title: const Text("Discusión"),
      ),
      body: asyncPosts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No hay mensajes en esta discusión.'));
          }

          posts.sort((a, b) => (a['timecreated'] as int).compareTo(b['timecreated'] as int));
          // Si hay datos, construimos la lista de posts (pregunta y respuestas)
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final bool isOriginalPost = post['parentid'] == 0;

              return Card(
                margin: EdgeInsets.only(
                  // Añadimos sangría a las respuestas
                  left: isOriginalPost ? 0 : 24.0, 
                  bottom: 12.0
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['subject'] ?? 'Sin asunto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isOriginalPost ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'por ${post['author']['fullname'] ?? 'Anónimo'}',
                         style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Divider(height: 20),
                      Html(data: post['message'] ?? ''),
                      

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