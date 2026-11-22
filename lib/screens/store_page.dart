import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/feature_service.dart';
import '../widgets/admin_drawer.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final FeatureService _service = FeatureService();
  late Future<List<Map<String, dynamic>>> _products;
  Map<String, dynamic> _user = const {};
  bool _argumentsRead = false;
  final Set<int> _adding = {};

  @override
  void initState() {
    super.initState();
    _products = _service.productos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _user = Map<String, dynamic>.from(args);
    _argumentsRead = true;
  }

  Future<void> _add(int id) async {
    setState(() => _adding.add(id));
    try {
      await _service.agregarAlCarrito(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado al carrito.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo agregar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding.remove(id));
    }
  }

  void _navigate(String route) =>
      Navigator.pushReplacementNamed(context, route, arguments: _user);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tienda'),
      actions: [
        IconButton(
          tooltip: 'Carrito',
          onPressed: () => Navigator.pushNamed(
            context,
            '/cart',
            arguments: _user,
          ),
          icon: const Icon(Icons.shopping_cart_outlined),
        ),
        IconButton(
          tooltip: 'Mis pedidos',
          onPressed: () => _navigate('/orders'),
          icon: const Icon(Icons.receipt_long_outlined),
        ),
      ],
    ),
    drawer: AdminDrawer(usuario: _user, rutaActual: '/store'),
    bottomNavigationBar: NavigationBar(
      selectedIndex: 1,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          label: 'Tienda',
        ),
        NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Mensajes'),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Pedidos',
        ),
      ],
      onDestinationSelected: (index) {
        const routes = ['/blog', '/store', '/messages', '/orders'];
        if (index != 1) _navigate(routes[index]);
      },
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _products,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No se pudieron cargar los productos: ${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(() => _products = _service.productos()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const Center(child: Text('Tienda sin productos.'));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 330,
            mainAxisExtent: 340,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final id = (product['id_prod'] as num).toInt();
            final image = ApiClient.assetUrl(
              product['imagen_url']?.toString() ?? product['img']?.toString(),
            );
            final stock = (product['stock'] as num?)?.toInt() ?? 0;
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: image.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFF1E7D9),
                            child: Icon(Icons.album_outlined, size: 56),
                          )
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFFF1E7D9),
                              child: Icon(Icons.album_outlined, size: 56),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['nombre']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '\$${(product['precio'] as num).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text('Disponibles: $stock'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: stock < 1 || _adding.contains(id)
                              ? null
                              : () => _add(id),
                          icon: _adding.contains(id)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_shopping_cart),
                          label: Text(stock < 1 ? 'Agotado' : 'Agregar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FeatureService _service = FeatureService();
  late Future<Map<String, dynamic>> _cart;
  Map<String, dynamic> _user = const {};
  bool _argumentsRead = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cart = _service.carrito();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _user = Map<String, dynamic>.from(args);
    _argumentsRead = true;
  }

  void _refresh() => setState(() => _cart = _service.carrito());

  Future<void> _remove(int itemId) async {
    try {
      await _service.quitarDelCarrito(itemId);
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo quitar el producto: $error')),
        );
      }
    }
  }

  Future<Map<String, String>?> _addressDialog() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final phone = TextEditingController();
    final city = TextEditingController();
    final postal = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Datos de envío'),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe el nombre.'
                        : null,
                  ),
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe la dirección.'
                        : null,
                  ),
                  TextFormField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  TextFormField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'Ciudad'),
                  ),
                  TextFormField(
                    controller: postal,
                    decoration: const InputDecoration(
                      labelText: 'Código postal',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, {
                'nombre': name.text.trim(),
                'direccion': address.text.trim(),
                'telefono': phone.text.trim(),
                'ciudad': city.text.trim(),
                'codigoPostal': postal.text.trim(),
              });
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    name.dispose();
    address.dispose();
    phone.dispose();
    city.dispose();
    postal.dispose();
    return result;
  }

  Future<void> _checkout() async {
    final address = await _addressDialog();
    if (address == null) return;
    setState(() => _saving = true);
    try {
      final order = await _service.finalizarCompra(
        nombre: address['nombre']!,
        direccion: address['direccion']!,
        telefono: address['telefono'],
        ciudad: address['ciudad'],
        codigoPostal: address['codigoPostal'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido ${order['folio']} creado.')),
      );
      Navigator.pushReplacementNamed(context, '/orders', arguments: _user);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el pedido: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Carrito')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _cart,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('No se pudo cargar el carrito: ${snapshot.error}'));
        }
        final cart = snapshot.data!;
        final items = (cart['items'] as List? ?? []).cast<Map<String, dynamic>>();
        if (items.isEmpty) return const Center(child: Text('Tu carrito está vacío.'));
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final product = item['producto'] as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(product['nombre']?.toString() ?? ''),
                      subtitle: Text(
                        '${item['cantidad']} × \$${(product['precio'] as num).toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Quitar',
                        onPressed: () => _remove((item['id_item'] as num).toInt()),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Subtotal: \$${(cart['subtotal'] as num).toStringAsFixed(2)}'),
                    Text('Envío: \$${(cart['envio'] as num).toStringAsFixed(2)}'),
                    Text(
                      'Total: \$${(cart['total'] as num).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _saving ? null : _checkout,
                      child: Text(_saving ? 'Procesando...' : 'Finalizar compra'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
