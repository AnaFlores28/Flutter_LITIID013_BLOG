import 'package:flutter/material.dart';

/// Contenedor de ancho controlado para formularios de autenticación.
class AuthCard extends StatelessWidget {

  final Widget child;

  const AuthCard({
    super.key,
    required this.child,
  });

  /// Presenta el contenido dentro de una tarjeta con espaciado uniforme.
  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 10,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: SizedBox(
          width: 340,
          child: child,
        ),
      ),
    );
  }
}