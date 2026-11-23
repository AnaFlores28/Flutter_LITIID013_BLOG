import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/admin_drawer.dart';

/// Permite consultar y actualizar los datos editables del perfil autenticado.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _bio = TextEditingController();
  final _generos = TextEditingController();
  final _telefono = TextEditingController();
  Map<String, dynamic> _usuario = {};
  bool _cargando = false;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }
    _nombre.text = _usuario['nom_usr']?.toString() ?? '';
    _direccion.text = _usuario['dir_usr']?.toString() ?? '';
    _bio.text = _usuario['bio']?.toString() ?? '';
    _generos.text = _usuario['generos']?.toString() ?? '';
    _telefono.text = _usuario['tel']?.toString() ?? '';
    _inicializado = true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _bio.dispose();
    _generos.dispose();
    _telefono.dispose();
    super.dispose();
  }

  /// Valida el formulario y envía los cambios de perfil a la API.
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usuario['id_usr'] == null || ApiClient.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión no está disponible. Vuelve a iniciar sesión.'),
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      final result = await ApiClient.send(
        'PUT',
        '/perfil',
        body: {
          'nom_usr': _nombre.text.trim(),
          'dir_usr': _direccion.text.trim().isEmpty
              ? null
              : _direccion.text.trim(),
          'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          'generos': _generos.text.trim().isEmpty
              ? null
              : _generos.text.trim(),
          'tel': _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
        },
      );
      if (result is! Map<String, dynamic>) {
        throw Exception('La respuesta del perfil no es válida.');
      }
      if (!mounted) return;
      setState(() => _usuario = Map<String, dynamic>.from(result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el perfil: $error')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Renderiza los campos de perfil y su acción de guardado.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi perfil')),
    drawer: AdminDrawer(usuario: _usuario, rutaActual: '/profile'),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
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
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFFFD93D),
                      child: Icon(
                        Icons.person,
                        size: 42,
                        color: Color(0xFF4F200D),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nombre,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? 'Ingresa un nombre válido.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                      ),
                      child: Text(_usuario['mail']?.toString() ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccion,
                      maxLength: 255,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bio,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Biografía'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _generos,
                      maxLength: 255,
                      decoration: const InputDecoration(
                        labelText: 'Géneros musicales favoritos',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefono,
                      maxLength: 20,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _cargando ? null : _guardar,
                      icon: _cargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_cargando ? 'Guardando...' : 'Guardar cambios'),
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
