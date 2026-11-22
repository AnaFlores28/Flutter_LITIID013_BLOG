import 'api_client.dart';

class FeatureService {
  Future<List<Map<String, dynamic>>> _list(String path) async {
    final value = await ApiClient.get(path);
    if (value is! List) throw Exception('La respuesta de la API no es válida.');
    return value.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _map(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final value = method == 'GET'
        ? await ApiClient.get(path, query: query)
        : await ApiClient.send(method, path, body: body, query: query);
    if (value is! Map<String, dynamic>) {
      throw Exception('La respuesta de la API no es válida.');
    }
    return value;
  }

  Future<List<Map<String, dynamic>>> productos() => _list('/productos');
  Future<Map<String, dynamic>> carrito() => _map('GET', '/carrito');

  Future<Map<String, dynamic>> agregarAlCarrito(int productId) =>
      _map('POST', '/carrito/items', body: {'producto_id': productId});

  Future<Map<String, dynamic>> cambiarCantidad(int itemId, int quantity) =>
      _map('PUT', '/carrito/items/$itemId', query: {'cantidad': '$quantity'});

  Future<Map<String, dynamic>> quitarDelCarrito(int itemId) =>
      _map('DELETE', '/carrito/items/$itemId');

  Future<Map<String, dynamic>> finalizarCompra({
    required String nombre,
    required String direccion,
    String? telefono,
    String? colonia,
    String? ciudad,
    String? estado,
    String? codigoPostal,
  }) => _map(
    'POST',
    '/pedidos',
    body: {
      'nombre_dest': nombre,
      'direccion': direccion,
      'tel': telefono,
      'colonia': colonia,
      'ciudad': ciudad,
      'estado': estado,
      'cp': codigoPostal,
    },
  );

  Future<Map<String, dynamic>> registrarPago(
    int orderId,
    String reference,
    String method,
  ) => _map(
    'POST',
    '/pedidos/$orderId/pago',
    body: {'referencia': reference, 'metodo': method},
  );

  Future<List<Map<String, dynamic>>> pedidos() => _list('/pedidos');
  Future<List<Map<String, dynamic>>> pedidosAdmin() =>
      _list('/admin/pedidos');

  Future<Map<String, dynamic>> cambiarEstadoPedido(
    int orderId,
    String paymentStatus,
    String shippingStatus,
  ) => _map(
    'PUT',
    '/admin/pedidos/$orderId',
    body: {
      'estado_pago': paymentStatus,
      'estado_envio': shippingStatus,
    },
  );

  Future<List<Map<String, dynamic>>> conversaciones() =>
      _list('/conversaciones');

  Future<List<Map<String, dynamic>>> buscarUsuarios(String query) async {
    final value = await ApiClient.get(
      '/usuarios/buscar',
      query: {'q': query},
    );
    if (value is! List) throw Exception('La respuesta de la API no es válida.');
    return value.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> iniciarConversacion(int userId) =>
      _map('POST', '/conversaciones', body: {'usuario_id': userId});

  Future<List<Map<String, dynamic>>> mensajes(int conversationId) =>
      _list('/conversaciones/$conversationId/mensajes');

  Future<Map<String, dynamic>> enviarMensaje(
    int conversationId,
    String text,
  ) => _map(
    'POST',
    '/conversaciones/$conversationId/mensajes',
    body: {'texto': text},
  );

  Future<List<Map<String, dynamic>>> comentarios(int postId) =>
      _list('/blog/$postId/comentarios');

  Future<Map<String, dynamic>> comentar(
    int postId,
    String text, {
    int? parentId,
  }) async {
    final body = <String, dynamic>{
      'blog_id': postId,
      'comentario': text,
    };
    if (parentId != null) body['padre_id'] = parentId;
    return _map('POST', '/comentarios', body: body);
  }

  Future<Map<String, dynamic>> valorar(int postId, int stars) =>
      _map(
        'POST',
        '/blog/$postId/valoraciones',
        query: {'estrellas': '$stars'},
      );

  Future<Map<String, dynamic>> reportar(
    String type,
    int referenceId,
    String reason,
  ) => _map(
    'POST',
    '/reportes',
    body: {'tipo': type, 'ref_id': referenceId, 'motivo': reason},
  );

  Future<List<Map<String, dynamic>>> productosAdmin() =>
      _list('/admin/productos');

  Future<Map<String, dynamic>> guardarProducto(
    Map<String, dynamic> product, {
    int? id,
  }) => _map(
    id == null ? 'POST' : 'PUT',
    id == null ? '/admin/productos' : '/admin/productos/$id',
    body: product,
  );

  Future<void> desactivarProducto(int id) =>
      ApiClient.send('DELETE', '/admin/productos/$id').then((_) {});

  Future<List<Map<String, dynamic>>> reportes() => _list('/admin/reportes');

  Future<Map<String, dynamic>> actualizarReporte(
    int id,
    String status,
  ) => _map(
    'PUT',
    '/admin/reportes/$id',
    body: {'estatus': status},
  );

  Future<List<Map<String, dynamic>>> publicacionesAdmin() =>
      _list('/admin/publicaciones');

  Future<List<Map<String, dynamic>>> comentariosAdmin() =>
      _list('/admin/comentarios');

  Future<Map<String, dynamic>> moderarPublicacion(int id, int status) =>
      _map(
        'PUT',
        '/admin/publicaciones/$id',
        query: {'estatus': '$status'},
      );

  Future<Map<String, dynamic>> moderarComentario(int id, int status) =>
      _map(
        'PUT',
        '/admin/comentarios/$id',
        query: {'estatus': '$status'},
      );

  Future<Map<String, dynamic>> resumenAdmin() => _map('GET', '/admin/resumen');
}
