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
              final String profileUrl = member['profileimageurl'] ?? '';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  backgroundImage: profileUrl.isNotEmpty 
                    ? NetworkImage(profileUrl) 
                    : null,
                  child: Text(member['fullname'][0], style: const TextStyle(color: Colors.indigo)),
                ),
                title: Text(member['fullname'], style: const TextStyle(fontWeight: FontWeight.bold)),
                
                // --- CAMBIO EN EL SUBTÍTULO ---
                subtitle: Text(
                  (chat['unreadcount'] != null && chat['unreadcount'] > 0)
                      ? '📩 Mensaje pendiente'
                      : (chat['messages'].isNotEmpty ? 'Ver conversación' : 'Sin mensajes'),
                  style: TextStyle(
                    color: (chat['unreadcount'] != null && chat['unreadcount'] > 0) 
                        ? Colors.green.shade700 
                        : Colors.grey.shade600,
                    fontWeight: (chat['unreadcount'] != null && chat['unreadcount'] > 0) 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
                
                // --- INDICADOR VISUAL EXTRA ---
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chat['unreadcount'] != null && chat['unreadcount'] > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: Text(
                          '${chat['unreadcount']}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                
                onTap: () async {
                  context.push('/chat-detalle', extra: {
                    'conversationId': chat['id'],
                    'userName': member['fullname'],
                    'userIdTo': member['id'],
                  });
                  ref.invalidate(conversationsProvider);
                },
              );
              /*return ListTile(
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
              );*/
            },
          );
        },
      ),
    );
  }
}