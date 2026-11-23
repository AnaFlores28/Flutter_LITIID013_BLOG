import 'api_client.dart';

/// Agrupa las operaciones de tienda, pedidos, mensajería y administración.
class FeatureService {
  /// Comprueba que el endpoint devolvió una lista de objetos JSON.
  Future<List<Map<String, dynamic>>> _list(String path) async {
    final value = await ApiClient.get(path);
    if (value is! List) throw Exception('La respuesta de la API no es válida.');
    return value.cast<Map<String, dynamic>>();
  }

  /// Comprueba que un endpoint devolvió un objeto JSON.
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

  /// Obtiene el catálogo activo de productos.
  Future<List<Map<String, dynamic>>> productos() => _list('/productos');

  /// Obtiene el carrito de la cuenta autenticada.
  Future<Map<String, dynamic>> carrito() => _map('GET', '/carrito');

  /// Agrega un producto al carrito actual.
  Future<Map<String, dynamic>> agregarAlCarrito(int productId) =>
      _map('POST', '/carrito/items', body: {'producto_id': productId});

  /// Cambia la cantidad de un artículo del carrito.
  Future<Map<String, dynamic>> cambiarCantidad(int itemId, int quantity) =>
      _map('PUT', '/carrito/items/$itemId', query: {'cantidad': '$quantity'});

  /// Quita un artículo del carrito actual.
  Future<Map<String, dynamic>> quitarDelCarrito(int itemId) =>
      _map('DELETE', '/carrito/items/$itemId');

  /// Crea un pedido con los datos de envío y los artículos del carrito.
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

  /// Registra una referencia de pago para un pedido.
  Future<Map<String, dynamic>> registrarPago(
    int orderId,
    String reference,
    String method,
  ) => _map(
    'POST',
    '/pedidos/$orderId/pago',
    body: {'referencia': reference, 'metodo': method},
  );

  /// Lista los pedidos de la cuenta autenticada.
  Future<List<Map<String, dynamic>>> pedidos() => _list('/pedidos');

  /// Lista todos los pedidos para su administración.
  Future<List<Map<String, dynamic>>> pedidosAdmin() =>
      _list('/admin/pedidos');

  /// Actualiza los estados de pago y envío de un pedido.
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

  /// Lista las conversaciones de la cuenta autenticada.
  Future<List<Map<String, dynamic>>> conversaciones() =>
      _list('/conversaciones');

  /// Busca usuarios para iniciar una conversación.
  Future<List<Map<String, dynamic>>> buscarUsuarios(String query) async {
    final value = await ApiClient.get(
      '/usuarios/buscar',
      query: {'q': query},
    );
    if (value is! List) throw Exception('La respuesta de la API no es válida.');
    return value.cast<Map<String, dynamic>>();
  }

  /// Busca o crea una conversación con el usuario indicado.
  Future<Map<String, dynamic>> iniciarConversacion(int userId) =>
      _map('POST', '/conversaciones', body: {'usuario_id': userId});

  /// Recupera los mensajes de una conversación.
  Future<List<Map<String, dynamic>>> mensajes(int conversationId) =>
      _list('/conversaciones/$conversationId/mensajes');

  /// Envía un mensaje a una conversación existente.
  Future<Map<String, dynamic>> enviarMensaje(
    int conversationId,
    String text,
  ) => _map(
    'POST',
    '/conversaciones/$conversationId/mensajes',
    body: {'texto': text},
  );

  /// Lista comentarios visibles de una publicación.
  Future<List<Map<String, dynamic>>> comentarios(int postId) =>
      _list('/blog/$postId/comentarios');

  /// Crea un comentario y opcionalmente lo enlaza como respuesta.
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

  /// Crea o actualiza la valoración del usuario para una publicación.
  Future<Map<String, dynamic>> valorar(int postId, int stars) =>
      _map(
        'POST',
        '/blog/$postId/valoraciones',
        query: {'estrellas': '$stars'},
      );

  /// Envía un reporte de moderación sobre un elemento.
  Future<Map<String, dynamic>> reportar(
    String type,
    int referenceId,
    String reason,
  ) => _map(
    'POST',
    '/reportes',
    body: {'tipo': type, 'ref_id': referenceId, 'motivo': reason},
  );

  /// Lista productos activos e inactivos para administración.
  Future<List<Map<String, dynamic>>> productosAdmin() =>
      _list('/admin/productos');

  /// Crea un producto o actualiza el existente si se proporciona su ID.
  Future<Map<String, dynamic>> guardarProducto(
    Map<String, dynamic> product, {
    int? id,
  }) => _map(
    id == null ? 'POST' : 'PUT',
    id == null ? '/admin/productos' : '/admin/productos/$id',
    body: product,
  );

  /// Desactiva un producto desde el panel administrativo.
  Future<void> desactivarProducto(int id) =>
      ApiClient.send('DELETE', '/admin/productos/$id').then((_) {});

  /// Lista los reportes que requieren revisión administrativa.
  Future<List<Map<String, dynamic>>> reportes() => _list('/admin/reportes');

  /// Cambia el estado de un reporte de moderación.
  Future<Map<String, dynamic>> actualizarReporte(
    int id,
    String status,
  ) => _map(
    'PUT',
    '/admin/reportes/$id',
    body: {'estatus': status},
  );

  /// Lista publicaciones disponibles para moderación.
  Future<List<Map<String, dynamic>>> publicacionesAdmin() =>
      _list('/admin/publicaciones');

  /// Lista comentarios disponibles para moderación.
  Future<List<Map<String, dynamic>>> comentariosAdmin() =>
      _list('/admin/comentarios');

  /// Cambia la visibilidad de una publicación.
  Future<Map<String, dynamic>> moderarPublicacion(int id, int status) =>
      _map(
        'PUT',
        '/admin/publicaciones/$id',
        query: {'estatus': '$status'},
      );

  /// Cambia la visibilidad de un comentario.
  Future<Map<String, dynamic>> moderarComentario(int id, int status) =>
      _map(
        'PUT',
        '/admin/comentarios/$id',
        query: {'estatus': '$status'},
      );

  /// Obtiene los contadores agregados del panel administrativo.
  Future<Map<String, dynamic>> resumenAdmin() => _map('GET', '/admin/resumen');
}
