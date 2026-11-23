import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/feature_service.dart';

/// Detalle de una publicación con valoraciones, comentarios y reportes.
class PostDetailPage extends StatefulWidget {
  final PostModel post;
  final Map<String, dynamic> usuario;

  const PostDetailPage({
    super.key,
    required this.post,
    this.usuario = const {},
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final FeatureService _service = FeatureService();
  final TextEditingController _commentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _comments;
  bool _sending = false;
  int? _replyTo;

  @override
  void initState() {
    super.initState();
    _comments = _service.comentarios(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Envía un comentario o respuesta y actualiza la lista del detalle.
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.comentar(
        widget.post.id,
        text,
        parentId: _replyTo,
      );
      _commentController.clear();
      setState(() {
        _replyTo = null;
        _comments = _service.comentarios(widget.post.id);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo comentar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Solicita un motivo y reporta la publicación a la API.
  Future<void> _report() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar publicación'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar reporte'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.trim().length < 3) return;
    try {
      await _service.reportar('publicacion', widget.post.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar el reporte: $error')),
        );
      }
    }
  }

  /// Registra la valoración seleccionada para la publicación.
  Future<void> _rate(int stars) async {
    try {
      await _service.valorar(widget.post.id, stars);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gracias por tu valoración.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo valorar: $error')),
        );
      }
    }
  }

  /// Muestra el contenido y las acciones disponibles para la sesión actual.
  @override
  Widget build(BuildContext context) {
    final userId = (widget.usuario['id_usr'] as num?)?.toInt();
    final canReport = userId != null && userId != widget.post.autorId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        actions: [
          if (canReport)
            IconButton(
              tooltip: 'Reportar',
              onPressed: _report,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (widget.post.imagen.isNotEmpty)
            Image.network(
              widget.post.imagen,
              height: 245,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imagePlaceholder(),
            )
          else
            _imagePlaceholder(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(widget.post.tipo)),
                    if (widget.post.genero.isNotEmpty)
                      Chip(label: Text(widget.post.genero)),
                  ],
                ),
                Text(
                  widget.post.titulo,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (widget.post.autor.isNotEmpty) widget.post.autor,
                    if (widget.post.medioNombre.isNotEmpty)
                      widget.post.medioNombre,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                SelectableText(
                  widget.post.descripcion,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 18),
                const Text('¿Qué te pareció?'),
                Row(
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      tooltip: '${index + 1} estrellas',
                      onPressed: () => _rate(index + 1),
                      icon: const Icon(Icons.star_outline),
                    ),
                  ),
                ),
                const Divider(height: 32),
                Text(
                  'Comentarios',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (userId != null) ...[
                  if (_replyTo != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _replyTo = null),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar respuesta'),
                      ),
                    ),
                  TextField(
                    controller: _commentController,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: _replyTo == null
                          ? 'Escribe un comentario'
                          : 'Escribe una respuesta',
                      suffixIcon: IconButton(
                        onPressed: _sending ? null : _submitComment,
                        icon: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ),
                  ),
                ] else
                  const Text('Inicia sesión para comentar y valorar.'),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _comments,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('No se pudieron cargar los comentarios: ${snapshot.error}');
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Text('Aún no hay comentarios.');
                    }
                    return Column(
                      children: comments.map((comment) {
                        final isReply = comment['padre_id'] != null;
                        return Card(
                          margin: EdgeInsets.only(
                            left: isReply ? 24 : 0,
                            bottom: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment['nom_usr']?.toString() ??
                                      'Usuario',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(comment['comentario']?.toString() ?? ''),
                                if (userId != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => setState(
                                        () => _replyTo =
                                            (comment['id_com'] as num)
                                                .toInt(),
                                      ),
                                      child: const Text('Responder'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    height: 210,
    color: const Color(0xFFF1E7D9),
    child: const Icon(Icons.music_note, size: 60),
  );
}
