/// Representa un comentario recibido o creado mediante la API.
class ComentarioModel {
  final int id;
  final String comentario;
  final String fecha;
  final int estatus;
  final int usuarioId;
  final int blogId;

  ComentarioModel({
    required this.id,
    required this.comentario,
    required this.fecha,
    required this.estatus,
    required this.usuarioId,
    required this.blogId,
  });

  /// Crea un comentario a partir de las claves usadas por el backend.
  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    return ComentarioModel(
      id: json['id_com'] as int,
      comentario: json['comentario'] as String,
      fecha: json['fecha'] as String,
      estatus: json['estatus'] as int,
      usuarioId: json['usr_id'] as int,
      blogId: json['blog_id'] as int,
    );
  }

  /// Serializa los campos que el cliente envía al crear un comentario.
  Map<String, dynamic> toJsonCrear() {
    return {
      'comentario': comentario,
      'usr_id': usuarioId,
      'blog_id': blogId,
    };
  }
}