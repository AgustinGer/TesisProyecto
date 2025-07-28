import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/forum_provider.dart';
import 'package:go_router/go_router.dart';
//import 'package:flutter_tesis/providers/forum_provider.dart'; // Asegúrate de que la ruta sea correcta

class ForumScreen extends ConsumerWidget {
  final int forumId;
  const ForumScreen({super.key, required this.forumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDiscussions = ref.watch(forumDiscussionsProvider(forumId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Forum"),
      ),
      body: asyncDiscussions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (discussions) {
          if (discussions.isEmpty) {
            return const Center(child: Text('Este foro no tiene discusiones.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: discussions.length,
            itemBuilder: (context, index) {
              final discussion = discussions[index];
              return _DiscussionPost(discussion: discussion);
            },
            separatorBuilder: (context, index) => const Divider(height: 20),
          );
        },
      ),
    );
  }
}

// Widget para mostrar CADA discusión en la lista
// Widget para mostrar CADA discusión en la lista
class _DiscussionPost extends StatelessWidget {
  final Map<String, dynamic> discussion;
  const _DiscussionPost({required this.discussion});

  @override
  Widget build(BuildContext context) {
    final String subject = discussion['subject'] ?? 'Sin asunto';
    final String author = discussion['userfullname'] ?? 'Anónimo';
    final String messageSnippet = (discussion['message'] as String? ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .trim();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell( // Volvemos a usar InkWell porque ya sabemos que funciona
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // --- LA CORRECCIÓN ESTÁ AQUÍ ---
          // El ID de la discusión viene en la clave 'id'
          final dynamic discussionId = discussion['id']; 

          if (discussionId != null) {
            context.push('/foro/discusion/$discussionId');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se puede abrir esta discusión.')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('por $author', style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 16),
              Text(
                messageSnippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),
                      
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver discusión completa...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue.shade700, // Color azul
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/*
// Widget para mostrar una sola respuesta
class _DiscussionReply extends StatelessWidget {
  final Map<String, dynamic> reply;
  const _DiscussionReply({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Re: ${reply['subject'] ?? 'Sin asunto'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'por ${reply['userfullname'] ?? 'Anónimo'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 16),
            Html(data: reply['message'] ?? ''),
          ],
        ),
      ),
    );
  }
}*/