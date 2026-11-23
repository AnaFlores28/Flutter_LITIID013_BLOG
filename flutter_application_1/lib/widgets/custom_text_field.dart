import 'package:flutter/material.dart';

/// Campo de texto reutilizable para formularios de autenticación.
class CustomTextField extends StatelessWidget {

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  /// Aplica teclado, visibilidad y decoración según los parámetros del campo.
  @override
  Widget build(BuildContext context) {

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          prefixIcon,
        ),

        suffixIcon: suffixIcon,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(6),
        ),
      ),
    );
  }
}