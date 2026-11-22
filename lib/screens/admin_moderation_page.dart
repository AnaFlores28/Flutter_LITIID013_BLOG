import 'package:flutter/material.dart';

import '../services/feature_service.dart';
import '../widgets/admin_drawer.dart';

class AdminModerationPage extends StatefulWidget {
  const AdminModerationPage({super.key});

  @override
  State<AdminModerationPage> createState() => _AdminModerationPageState();
}

class _AdminModerationPageState extends State<AdminModerationPage> {
  final FeatureService _service = FeatureService();
  late Future<List<Map<String, dynamic>>> _posts;
  late Future<List<Map<String, dynamic>>> _comments;
  Map<String, dynamic> _user = const {};
  bool _argumentsRead = false;
  final Set<String> _updating = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _user = Map<String, dynamic>.from(args);
    _argumentsRead = true;
  }

  void _reload() {
    _posts = _service.publicacionesAdmin();
    _comments = _service.comentariosAdmin();
  }

  Future<void> _moderate({
    required String key,
    required int id,
    required int status,
    required bool post,
  }) async {
    setState(() => _updating.add(key));
    try {
      if (post) {
        await _service.moderarPublicacion(id, status);
      } else {
        await _service.moderarComentario(id, status);
      }
      if (mounted) {
        setState(() {
          _reload();
          _updating.remove(key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 1 ? 'Contenido restaurado.' : 'Contenido ocultado.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _updating.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo moderar el contenido: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Moderación'),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.article_outlined), text: 'Publicaciones'),
            Tab(icon: Icon(Icons.comment_outlined), text: 'Comentarios'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: AdminDrawer(usuario: _user, rutaActual: '/admin/moderation'),
      body: TabBarView(
        children: [
          _moderationList(
            future: _posts,
            isPost: true,
            idKey: 'id_blog',
            titleKey: 'titulo',
            bodyKey: 'contenido',
          ),
          _moderationList(
            future: _comments,
            isPost: false,
            idKey: 'id_com',
            titleKey: 'nom_usr',
            bodyKey: 'comentario',
          ),
        ],
      ),
    ),
  );

  Widget _moderationList({
    required Future<List<Map<String, dynamic>>> future,
    required bool isPost,
    required String idKey,
    required String titleKey,
    required String bodyKey,
  }) => FutureBuilder<List<Map<String, dynamic>>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Text('No se pudo cargar el contenido: ${snapshot.error}'),
        );
      }
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const Center(child: Text('No hay contenido.'));
      return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final id = (item[idKey] as num).toInt();
          final status = (item['estatus'] as num?)?.toInt() ?? 1;
          final key = '${isPost ? 'p' : 'c'}$id';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item[titleKey]?.toString() ?? 'Publicación',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text(status == 1 ? 'Visible' : 'Oculto'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item[bodyKey]?.toString() ?? '',
                    maxLines: isPost ? 5 : 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isPost) ...[
                    const SizedBox(height: 8),
                    Text('Autor: ${(item['autor'] as Map?)?['nom_usr'] ?? ''}'),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _updating.contains(key)
                          ? null
                          : () => _moderate(
                              key: key,
                              id: id,
                              status: status == 1 ? 0 : 1,
                              post: isPost,
                            ),
                      icon: _updating.contains(key)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              status == 1
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                      label: Text(status == 1 ? 'Ocultar' : 'Restaurar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
