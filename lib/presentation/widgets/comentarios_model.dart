import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesis/provider/coment_provider.dart';
import 'package:flutter_html/flutter_html.dart';

class ComentariosModal extends ConsumerStatefulWidget {
  final int contextId;
  final int entryId;
  final String entryTitle;

  const ComentariosModal({
    super.key, 
    required this.contextId, 
    required this.entryId,
    required this.entryTitle
  });

  @override
  ConsumerState<ComentariosModal> createState() => _ComentariosModalState();
}

class _ComentariosModalState extends ConsumerState<ComentariosModal> {
  final _textController = TextEditingController();
  bool _isSending = false;

  void _enviar() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    final success = await ref.read(commentActionsProvider).agregarComentario(
      contextId: widget.contextId,
      entryId: widget.entryId,
      texto: _textController.text,
    );

    setState(() => _isSending = false);

    if (success) {
      _textController.clear();
      // Refrescamos la lista de comentarios
      ref.invalidate(commentsProvider((contextId: widget.contextId, entryId: widget.entryId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los comentarios
    final commentsAsync = ref.watch(commentsProvider((contextId: widget.contextId, entryId: widget.entryId)));
    // Padding para cuando sale el teclado
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // 75% de la pantalla
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // CABECERA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Comentarios: ${widget.entryTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),

          // LISTA
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('No se pudieron cargar comentarios.\n(Quizás están deshabilitados)')),
              data: (comments) {
                if (comments.isEmpty) return const Center(child: Text('Sé el primero en comentar.', style: TextStyle(color: Colors.grey)));
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = comments[index];

                    final bool isValidAvatar = c.avatarUrl.startsWith('http') && !c.avatarUrl.contains('<');

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.indigo.shade100,
                              // Solo cargamos la imagen si la URL es válida
                              backgroundImage: isValidAvatar ? NetworkImage(c.avatarUrl) : null,
                              // Si no es válida, mostramos un icono por defecto
                              child: !isValidAvatar 
                                  ? const Icon(Icons.person, size: 20, color: Colors.indigo) 
                                  : null,
                            ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(c.timeCreated, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                //Text(c.content),
                              Html(
                                  data: c.content,
                                  style: {
                                    "body": Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                      fontSize: FontSize(14),
                                      color: Colors.black87,
                                    ),
                                    // Opcional: Eliminar márgenes extraños de los divs de Moodle
                                    "div": Style(
                                      margin: Margins.zero,
                                      padding: HtmlPaddings.zero,
                                    ),
                                  },
                                ),
                                
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // INPUT
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _isSending ? null : _enviar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}