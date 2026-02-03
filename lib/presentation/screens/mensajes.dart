import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/message_provider.dart';
import 'package:go_router/go_router.dart';

class MensajesScreen extends ConsumerWidget {
  const MensajesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: asyncConversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (conversations) {
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final member = chat['members'][0]; // El otro usuario
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(member['profileurl'] ?? ''),
                ),
                title: Text(member['fullname']),
                subtitle: Text(chat['messages'].isNotEmpty 
                    ? chat['messages'][0]['text'] 
                    : 'Sin mensajes'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navegar al chat individual
                  context.push('/chat-detalle', extra: {
                    'conversationId': chat['id'],
                    'userName': member['fullname'],
                    'userIdTo': member['id'],
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}