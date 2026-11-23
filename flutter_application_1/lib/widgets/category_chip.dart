import 'package:flutter/material.dart';

/// Chip seleccionable que comunica visualmente el estado de una categoría.
class CategoryChip extends StatelessWidget {

  final String text;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  /// Renderiza la etiqueta y notifica el toque al callback recibido.
  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 9,
        ),

        decoration: BoxDecoration(

          color: selected
              ? const Color(0xFF2196F3)
              : Colors.grey.shade200,

          borderRadius:
              BorderRadius.circular(20),
        ),

        child: Text(

          text,

          style: TextStyle(

            color: selected
                ? Colors.white
                : Colors.black87,

            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),
    );
  }
}