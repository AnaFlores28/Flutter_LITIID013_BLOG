import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';

/// Muestra, filtra y abre las publicaciones de la comunidad.
class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<PostModel>> _posts;
  Map<String, dynamic> _user = const {};
  String _query = '';
  bool _argumentsRead = false;

  @override
  void initState() {
    super.initState();
    _posts = _postService.obtenerPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      _user = Map<String, dynamic>.from(arguments);
    }
    _argumentsRead = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _posts = _postService.obtenerPosts());

  /// Busca por título, artista, género o etiqueta usando el texto normalizado.
  Future<void> _search() async {
    _searchController.text = _query;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar publicaciones'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Título, artista o género',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _searchController.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _query = result.trim().toLowerCase());
    }
  }

  /// Abre el formulario de creación y recarga el blog tras publicar.
  Future<void> _openCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearBlogForm()),
    );
    if (result == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación creada correctamente.')),
      );
    }
  }

  void _navigate(String route) {
    Navigator.pushReplacementNamed(context, route, arguments: _user);
  }

  /// Construye la lista filtrada y sus controles de navegación.
  @override
  Widget build(BuildContext context) {
    final isAdmin = (_user['tip_usu'] as num?)?.toInt() == 0;
    final userName = _user['nom_usr']?.toString() ?? 'Sound OAC';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sound OAC'),
            Text(
              'Hola, $userName',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            onPressed: _search,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: AdminDrawer(usuario: _user, rutaActual: '/blog'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        icon: const Icon(Icons.edit),
        label: const Text('Publicar'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Tienda',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: 'Mensajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Pedidos',
          ),
        ],
        onDestinationSelected: (index) {
          const routes = ['/blog', '/store', '/messages', '/orders'];
          if (index != 0) _navigate(routes[index]);
        },
      ),
      body: FutureBuilder<List<PostModel>>(
        future: _posts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: 'No se pudieron cargar las publicaciones.',
              detail: '${snapshot.error}',
              onRetry: _reload,
            );
          }
          final allPosts = snapshot.data ?? [];
          final posts = allPosts.where((post) {
            if (_query.isEmpty) return true;
            return '${post.titulo} ${post.medioNombre} ${post.genero} ${post.categoria}'
                .toLowerCase()
                .contains(_query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              final future = _postService.obtenerPosts();
              setState(() => _posts = future);
              await future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  'La comunidad Sound OAC',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reseñas, recomendaciones y conversaciones sobre música.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_query.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  InputChip(
                    label: Text('Búsqueda: $_query'),
                    onDeleted: () => setState(() => _query = ''),
                  ),
                ],
                const SizedBox(height: 18),
                if (posts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No hay publicaciones que coincidan.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...posts.map(
                    (post) => PostCard(
                      post: post,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(
                            post: post,
                            usuario: _user,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isAdmin)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings),
                      title: const Text('Herramientas de administración'),
                      subtitle: const Text('Modera contenido, pedidos y tienda'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/admin/moderation',
                        arguments: _user,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

/// Formulario para crear una publicación y adjuntar una imagen opcional.
class CrearBlogForm extends StatefulWidget {
  const CrearBlogForm({super.key});

  @override
  State<CrearBlogForm> createState() => _CrearBlogFormState();
}

class _CrearBlogFormState extends State<CrearBlogForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _artist = TextEditingController();
  final _genre = TextEditingController();
  final _tags = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  Uint8List? _imageBytes;
  String _type = 'resena';
  String _mediumType = 'artista';
  bool _saving = false;
  final PostService _service = PostService();

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _artist.dispose();
    _genre.dispose();
    _tags.dispose();
    super.dispose();
  }

  /// Selecciona una imagen y la lee para previsualizarla o enviarla a la API.
  Future<void> _pickImage() async {
    try {
      final selected = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _image = selected;
        _imageBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar la imagen: $error')),
      );
    }
  }

  /// Valida el formulario y crea la publicación mediante PostService.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.agregarPost(
        titulo: _title.text,
        descripcion: _content.text,
        medioNombre: _artist.text,
        genero: _genre.text,
        tipo: _type,
        medioTipo: _mediumType,
        tags: _tags.text,
        imagenBytes: _imageBytes,
        nombreArchivo: _image?.name,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Presenta los campos de publicación y el estado de envío.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear publicación')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Comparte con la comunidad',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Escribe un título.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _content,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el contenido.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'resena', child: Text('Reseña')),
                  DropdownMenuItem(
                    value: 'recomendacion',
                    child: Text('Recomendación'),
                  ),
                  DropdownMenuItem(value: 'noticia', child: Text('Noticia')),
                  DropdownMenuItem(value: 'cronica', child: Text('Crónica')),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _mediumType,
                decoration: const InputDecoration(labelText: 'Sobre'),
                items: const [
                  DropdownMenuItem(value: 'artista', child: Text('Artista')),
                  DropdownMenuItem(value: 'album', child: Text('Álbum')),
                ],
                onChanged: (value) =>
                    setState(() => _mediumType = value ?? _mediumType),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _artist,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Nombre del artista o álbum',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                    ? 'Indica el artista o álbum.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genre,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Género musical'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica el género.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Etiquetas (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_image?.name ?? 'Agregar imagen (opcional)'),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _imageBytes!,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: Text(_saving ? 'Publicando...' : 'Publicar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
