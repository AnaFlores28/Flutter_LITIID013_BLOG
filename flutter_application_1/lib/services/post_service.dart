import 'dart:typed_data';

import '../models/post_model.dart';
import 'api_client.dart';

/// Implementa la consulta y publicación de entradas del blog.
class PostService {
  /// Recupera las publicaciones visibles y las convierte en modelos.
  Future<List<PostModel>> obtenerPosts() async {
    final data = await ApiClient.get('/blog', authenticated: false);
    if (data is! List) throw Exception('La lista de publicaciones no es válida.');
    return data
        .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Publica una entrada, usando multipart cuando se adjunta una imagen.
  Future<void> agregarPost({
    required String titulo,
    required String descripcion,
    required String medioNombre,
    required String genero,
    required String tipo,
    required String medioTipo,
    Uint8List? imagenBytes,
    String? nombreArchivo,
    String tags = '',
  }) async {
    final fields = {
      'titulo': titulo.trim(),
      'contenido': descripcion.trim(),
      'medio_nombre': medioNombre.trim(),
      'genero': genero.trim(),
      'tipo': tipo,
      'medio_tipo': medioTipo,
      'tags': tags.trim(),
    };
    if (imagenBytes != null && nombreArchivo != null) {
      await ApiClient.upload(
        '/blog/imagen',
        fields: fields,
        fileField: 'imagen',
        filename: nombreArchivo,
        bytes: imagenBytes,
      );
    } else {
      await ApiClient.send('POST', '/blog', body: fields);
    }
  }
}