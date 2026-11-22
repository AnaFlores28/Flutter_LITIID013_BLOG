import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nombreController = TextEditingController();

  final TextEditingController correoController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmarPasswordController =
      TextEditingController();

  final AuthService authService = AuthService();

  Map<String, dynamic> _usuario = {};

  int tipoUsuario = 1;
  bool registrando = false;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_inicializado) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }

    _inicializado = true;
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmarPasswordController.dispose();

    super.dispose();
  }

  Future<void> registrarUsuario() async {
    final mensaje = authService.validarRegistro(
      nombre: nombreController.text.trim(),
      correo: correoController.text.trim(),
      password: passwordController.text,
      confirmarpassword: confirmarPasswordController.text,
    );

    if (mensaje != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));

      return;
    }

    setState(() {
      registrando = true;
    });

    try {
      await authService.registrar(
        nombre: nombreController.text,
        correo: correoController.text,
        password: passwordController.text,
        tipoUsuario: tipoUsuario,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );

      nombreController.clear();
      correoController.clear();
      passwordController.clear();
      confirmarPasswordController.clear();

      setState(() {
        tipoUsuario = 1;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          registrando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = (_usuario['tip_usu'] as num?)?.toInt() == 0;
    final nombre = _usuario['nom_usr']?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar usuario')),
      drawer: esAdmin
          ? AdminDrawer(usuario: _usuario, rutaActual: '/register')
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 65,
                    color: Color(0xFFFF9A00),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'REGISTRAR USUARIO',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F200D),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    esAdmin
                        ? 'Administrador: ${nombre ?? 'Administrador'}'
                        : 'Crea tu cuenta de Sound OAC',
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),

                  const SizedBox(height: 25),

                  CustomTextField(
                    controller: nombreController,
                    label: 'Nombre completo',
                    prefixIcon: Icons.person,
                  ),

                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: correoController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                  ),

                  const SizedBox(height: 15),

                  CustomTextField(
                    controller: confirmarPasswordController,
                    label: 'Confirmar contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                  ),

                  const SizedBox(height: 15),

                  if (esAdmin)
                    DropdownButtonFormField<int>(
                      initialValue: tipoUsuario,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de usuario',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Usuario general'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => tipoUsuario = valor);
                        }
                      },
                    ),

                  const SizedBox(height: 25),

                  PrimaryButton(
                    text: registrando ? 'REGISTRANDO...' : 'REGISTRAR USUARIO',
                    onPressed: registrando ? () {} : registrarUsuario,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
