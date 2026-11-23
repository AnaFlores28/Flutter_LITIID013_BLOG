import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comentario_model.dart';

/// Cliente HTTP legado para consultar y crear comentarios.
class ComentarioService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Recupera y convierte la lista de comentarios de la API.
  Future<List<ComentarioModel>> obtenerComentarios() async {
    final respuesta = await http.get(
      Uri.parse('$baseUrl/comentarios'),
    );

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar comentarios');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map(
          (json) => ComentarioModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Envía el comentario serializado y falla si la API no confirma su creación.
  Future<void> agregarComentario(
    ComentarioModel comentario,
  ) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/comentarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(comentario.toJsonCrear()),
    );

    if (respuesta.statusCode != 201) {
      throw Exception(
        'No se pudo registrar el comentario: ${respuesta.body}',
      );
    }
  }
}