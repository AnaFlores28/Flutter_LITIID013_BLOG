import 'package:flutter/material.dart';

import '../services/feature_service.dart';
import '../widgets/admin_drawer.dart';

/// Panel administrativo de métricas, productos y reportes de usuarios.
class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  final FeatureService _service = FeatureService();
  late Future<List<Map<String, dynamic>>> _products;
  late Future<List<Map<String, dynamic>>> _reports;
  late Future<Map<String, dynamic>> _summary;
  Map<String, dynamic> _user = const {};
  bool _argumentsRead = false;
  bool _saving = false;

  static const _categories = [
    'poster',
    'taza',
    'playera',
    'libreta',
    'accesorio',
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _user = Map<String, dynamic>.from(args);
    _argumentsRead = true;
  }

  /// Actualiza los datos mostrados en las pestañas del panel.
  void _reload() {
    _products = _service.productosAdmin();
    _reports = _service.reportes();
    _summary = _service.resumenAdmin();
  }

  void _refresh() => setState(_reload);

  /// Abre y valida el formulario de alta o edición de un producto.
  Future<void> _editProduct([Map<String, dynamic>? product]) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: product?['nombre']?.toString());
    final description = TextEditingController(
      text: product?['descripcion']?.toString(),
    );
    final price = TextEditingController(
      text: product?['precio']?.toString() ?? '',
    );
    final stock = TextEditingController(
      text: product?['stock']?.toString() ?? '0',
    );
    final image = TextEditingController(text: product?['img']?.toString());
    var category = _categories.contains(product?['categoria'])
        ? product!['categoria'].toString()
        : _categories.first;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Nuevo producto' : 'Editar producto'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      maxLength: 150,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Escribe el nombre.'
                          : null,
                    ),
                    TextFormField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    TextFormField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Precio'),
                      validator: (value) =>
                          double.tryParse(value ?? '') == null ||
                              double.parse(value!) < 0
                          ? 'Indica un precio válido.'
                          : null,
                    ),
                    TextFormField(
                      controller: stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Existencias'),
                      validator: (value) =>
                          int.tryParse(value ?? '') == null ||
                              int.parse(value!) < 0
                          ? 'Indica una cantidad válida.'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: _categories
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setDialogState(
                        () => category = value ?? category,
                      ),
                    ),
                    TextFormField(
                      controller: image,
                      decoration: const InputDecoration(
                        labelText: 'Archivo de imagen (opcional)',
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
                  'descripcion': description.text.trim(),
                  'precio': double.parse(price.text),
                  'stock': int.parse(stock.text),
                  'categoria': category,
                  'img': image.text.trim().isEmpty ? null : image.text.trim(),
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    description.dispose();
    price.dispose();
    stock.dispose();
    image.dispose();
    if (result == null) return;
    setState(() => _saving = true);
    try {
      final id = (product?['id_prod'] as num?)?.toInt();
      await _service.guardarProducto(result, id: id);
      if (mounted) {
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el producto: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Desactiva un producto y actualiza la lista del panel.
  Future<void> _deactivate(Map<String, dynamic> product) async {
    final id = (product['id_prod'] as num).toInt();
    try {
      await _service.desactivarProducto(id);
      if (mounted) {
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto desactivado.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo desactivar: $error')),
        );
      }
    }
  }

  /// Cambia el estado de un reporte y vuelve a cargar sus datos.
  Future<void> _updateReport(int id, String status) async {
    try {
      await _service.actualizarReporte(id, status);
      if (mounted) _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el reporte: $error')),
        );
      }
    }
  }

  /// Presenta los indicadores, el catálogo administrable y los reportes.
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Herramientas de administración'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumen'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
            Tab(icon: Icon(Icons.flag_outlined), text: 'Reportes'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: AdminDrawer(usuario: _user, rutaActual: '/admin/tools'),
      body: TabBarView(
        children: [
          _summaryTab(),
          _productsTab(),
          _reportsTab(),
        ],
      ),
    ),
  );

  Widget _summaryTab() => FutureBuilder<Map<String, dynamic>>(
    future: _summary,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('No se pudo cargar el resumen: ${snapshot.error}'));
      }
      final summary = snapshot.data ?? {};
      const labels = {
        'usuarios': 'Usuarios',
        'publicaciones': 'Publicaciones visibles',
        'comentarios': 'Comentarios visibles',
        'pedidos': 'Pedidos',
        'reportes_pendientes': 'Reportes pendientes',
      };
      return GridView(
        padding: const EdgeInsets.all(18),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisExtent: 130,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        children: labels.entries
            .map(
              (entry) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.value),
                      Text(
                        '${summary[entry.key] ?? 0}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Widget _productsTab() => Column(
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _editProduct(),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo producto'),
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _products,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('No se pudieron cargar los productos: ${snapshot.error}'),
              );
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const Center(child: Text('No hay productos registrados.'));
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final active = (product['estatus'] as num?)?.toInt() == 1;
                return Card(
                  child: ListTile(
                    title: Text(product['nombre']?.toString() ?? ''),
                    subtitle: Text(
                      '${product['categoria']} · \$${product['precio']} · Stock: ${product['stock']} · ${active ? 'Activo' : 'Inactivo'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') _editProduct(product);
                        if (action == 'deactivate') _deactivate(product);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        if (active)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Desactivar'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );

  Widget _reportsTab() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _reports,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('No se pudieron cargar los reportes: ${snapshot.error}'));
      }
      final reports = snapshot.data ?? [];
      if (reports.isEmpty) return const Center(child: Text('No hay reportes.'));
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          final id = (report['id_rep'] as num).toInt();
          final status = report['estatus']?.toString() ?? 'pendiente';
          return Card(
            child: ListTile(
              title: Text(
                '${report['tipo']} #${report['ref_id']} · $status',
              ),
              subtitle: Text(report['motivo']?.toString() ?? ''),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _updateReport(id, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'resuelto',
                    child: Text('Marcar resuelto'),
                  ),
                  PopupMenuItem(
                    value: 'descartado',
                    child: Text('Descartar'),
                  ),
                  PopupMenuItem(
                    value: 'pendiente',
                    child: Text('Reabrir'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
