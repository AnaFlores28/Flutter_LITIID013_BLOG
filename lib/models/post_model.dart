import '../services/api_client.dart';

class PostModel {
  final int id;
  final int autorId;
  final String autor;
  final String titulo;
  final String descripcion;
  final String imagen;
  final String categoria;
  final String tipo;
  final String medioNombre;
  final String genero;
  final DateTime? fecha;

  PostModel({
    required this.id,
    this.autorId = 0,
    this.autor = '',
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.categoria,
    this.tipo = 'resena',
    this.medioNombre = '',
    this.genero = '',
    this.fecha,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final author = json['autor'];
    return PostModel(
      id: (json['id_blog'] as num).toInt(),
      autorId: (json['usr_id'] as num?)?.toInt() ??
          (author is Map ? (author['id_usr'] as num?)?.toInt() : null) ??
          0,
      autor: author is Map ? author['nom_usr']?.toString() ?? '' : '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion:
          json['contenido']?.toString() ??
          json['descripcion']?.toString() ??
          json['desc']?.toString() ??
          '',
      imagen: ApiClient.assetUrl(
        json['imagen_url']?.toString() ?? json['img']?.toString(),
      ),
      categoria: json['tags'] as String? ?? 'General',
      tipo: json['tipo']?.toString() ?? 'resena',
      medioNombre: json['medio_nombre']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
    );
  }
}