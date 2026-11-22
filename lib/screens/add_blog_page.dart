import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../widgets/admin_drawer.dart';

class AddBlogPage extends StatefulWidget {
  const AddBlogPage({super.key});

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  static const String baseUrl = 'http://127.0.0.1:8000';

  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _foto;
  Uint8List? _imagenBytes;

  bool _enviando = false;
  Map<String, dynamic> _usuario = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final imagen = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      setState(() {
        _foto = imagen;
        _imagenBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo tomar la fotografía: $e')),
      );
    }
  }

  Future<void> _seleccionarFoto() async {
    try {
      final imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      setState(() {
        _foto = imagen;
        _imagenBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar la imagen: $e')),
      );
    }
  }

  Future<void> _enviarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    if (_foto == null || _imagenBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes capturar o seleccionar una fotografía'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final uri = Uri.parse('$baseUrl/blog');

      final request = http.MultipartRequest('POST', uri)
        ..fields['titulo'] = _titulo.text.trim()
        ..fields['descripcion'] = _descripcion.text.trim()
        ..files.add(
          http.MultipartFile.fromBytes(
            'imagen',
            _imagenBytes!,
            filename: _foto!.name,
          ),
        );

      final respuesta = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final cuerpo = await respuesta.stream.bytesToString();

      if (!mounted) return;

      if (respuesta.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación guardada correctamente')),
        );

        _titulo.clear();
        _descripcion.clear();

        setState(() {
          _foto = null;
          _imagenBytes = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${respuesta.statusCode}: $cuerpo'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _usuario['nom_usr']?.toString() ?? 'Administrador';

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar blog')),
      drawer: AdminDrawer(usuario: _usuario, rutaActual: '/add-blog'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nueva publicación',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text('Administrador: $nombre'),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titulo,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().length < 2
                            ? 'Ingresa el título'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descripcion,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v == null || v.trim().length < 5
                            ? 'Ingresa una descripción de al menos 5 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      if (_imagenBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _imagenBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _tomarFoto,
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('Cámara'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _seleccionarFoto,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galería'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _enviando ? null : _enviarRegistro,
                        icon: _enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _enviando ? 'Guardando...' : 'Guardar publicación',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
