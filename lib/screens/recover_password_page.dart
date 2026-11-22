import 'package:flutter/material.dart';

class RecoverPage extends StatefulWidget {
  const RecoverPage({super.key});

  @override
  State<RecoverPage> createState() =>
      _RecoverPageState();
}

class _RecoverPageState
    extends State<RecoverPage> {

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    correoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [

            const Icon(
              Icons.person_add,
              size: 70,
            ),

            const SizedBox(height: 20),

            const Text(
              'RECUPERAR CONTRASEÑA',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),



            const SizedBox(height: 15),

            TextField(
              controller:
                  correoController,

              decoration:
                  const InputDecoration(
                labelText:
                    'Correo electrónico',
                prefixIcon:
                    Icon(Icons.email),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller:
                  passwordController,

              obscureText: true,

              decoration:
                  const InputDecoration(
                labelText:
                    'Nueva contraseña',
                prefixIcon:
                    Icon(Icons.lock),
                border:
                    OutlineInputBorder(),
              ),
            ),
            TextField(
              controller:
                  confirmPasswordController,

              obscureText: true,

              decoration:
                  const InputDecoration(
                labelText:
                    'Confirmar nueva contraseña',
                prefixIcon:
                    Icon(Icons.lock),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Contraseña recuperada exitosamente',
                      ),
                    ),
                  );
                },

                child:
                    const Text('RECUPERAR CONTRASEÑA'),
              ),
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Ya tengo una cuenta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}