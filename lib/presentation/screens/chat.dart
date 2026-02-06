import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/auth_provider.dart';
import 'package:flutter_tesis/provider/course_actions_provider.dart';
//import 'package:flutter_tesis/provider/course_actions_provider.dart';
import 'package:flutter_tesis/provider/message_provider.dart';
import 'dart:async';

class ChatDetalleScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String userName;
  final int userIdTo;

  const ChatDetalleScreen({
    super.key,
    required this.conversationId,
    required this.userName,
    required this.userIdTo,
  });

  @override
  ConsumerState<ChatDetalleScreen> createState() => _ChatDetalleScreenState();
}

class _ChatDetalleScreenState extends ConsumerState<ChatDetalleScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Añadido para el scroll
  Timer? _pollingTimer;

  
    @override
    void initState() {
      super.initState();
      
      // Marcamos como leído apenas entramos a la pantalla
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(courseActionsProvider).marcarComoLeido(
          conversationId: widget.conversationId
        );
      });
      _iniciarActualizacionAutomatica();
    }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviarChat() async {
    if (_controller.text.trim().isEmpty) return;

    final textoOriginal = _controller.text.trim();
    
    // Llamamos al provider de acciones
    final success = await ref.read(courseActionsProvider).enviarMensaje(
      userIdTo: widget.userIdTo,
      texto: textoOriginal,
    );

    if (success) {
      _controller.clear(); // Limpiamos el campo
      
      // Invalidamos el provider para recargar la lista de mensajes
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      
      // Animamos el scroll hacia el nuevo mensaje (posición 0 porque es reverse: true)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0, 
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje')),
      );
    }
  }

void _iniciarActualizacionAutomatica() {
    // En una institución, 10-15 segundos es un equilibrio sano entre "tiempo real" y "carga del servidor"
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // Refrescamos silenciosamente el provider
        ref.invalidate(chatMessagesProvider(widget.conversationId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los mensajes y el ID del usuario actual
    final asyncMessages = ref.watch(chatMessagesProvider(widget.conversationId));
    final myId = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: asyncMessages.when(
              data: (messages) {
                print('DEBUG UI: Renderizando mensajes. Cantidad: ${messages.length}');

                if (messages.isEmpty) {
                  return const Center(child: Text("No hay mensajes en esta conversación."));
                }

                return ListView.builder(
                  controller: _scrollController, // IMPORTANTE: Asignar el controlador
                  reverse: true, 
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['useridfrom'] == myId;

                    return _BubbleChat(
                      text: msg['text'] ?? '',
                      isMe: isMe,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                print('DEBUG UI ERROR: $err');
                return Center(child: Text('Error al cargar chat: $err'));
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              backgroundColor: Colors.indigo,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _enviarChat, // Conectado a la función lógica
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleChat extends StatelessWidget {
  final String text;
  final bool isMe;

  const _BubbleChat({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Limpiamos etiquetas HTML básicas que Moodle suele enviar
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
      //  maxSize: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.indigo : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(
          cleanText,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}