import 'package:flutter/material.dart';

import '../services/feature_service.dart';
import '../widgets/admin_drawer.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FeatureService _service = FeatureService();
  late Future<List<Map<String, dynamic>>> _orders;
  Map<String, dynamic> _user = const {};
  bool _argumentsRead = false;
  final Set<int> _paying = {};

  @override
  void initState() {
    super.initState();
    _orders = _service.pedidos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _user = Map<String, dynamic>.from(args);
    _argumentsRead = true;
  }

  void _reload() => setState(() => _orders = _service.pedidos());

  Future<void> _registerPayment(Map<String, dynamic> order) async {
    final reference = TextEditingController();
    String method = 'transferencia';
    final formKey = GlobalKey<FormState>();
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar pago'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pedido ${order['folio']} · \$${order['total']}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Método'),
                  items: const [
                    DropdownMenuItem(
                      value: 'transferencia',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => method = value ?? method),
                ),
                TextFormField(
                  controller: reference,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Referencia o folio',
                  ),
                  validator: (value) =>
                      value == null || value.trim().length < 3
                      ? 'Escribe una referencia válida.'
                      : null,
                ),
              ],
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
                  'metodo': method,
                  'referencia': reference.text.trim(),
                });
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    reference.dispose();
    if (values == null) return;
    final id = (order['id_ped'] as num).toInt();
    setState(() => _paying.add(id));
    try {
      await _service.registrarPago(
        id,
        values['referencia']!,
        values['metodo']!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago enviado para validación.')),
        );
        _reload();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar el pago: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _paying.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = (_user['tip_usu'] as num?)?.toInt() == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Administrar pedidos',
              onPressed: () => Navigator.pushNamed(
                context,
                '/admin/orders',
                arguments: _user,
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: AdminDrawer(usuario: _user, rutaActual: '/orders'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('No se pudieron cargar los pedidos: ${snapshot.error}'),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const Center(child: Text('Aún no tienes pedidos.'));
          return RefreshIndicator(
            onRefresh: () async {
              final future = _service.pedidos();
              setState(() => _orders = future);
              await future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final id = (order['id_ped'] as num).toInt();
                final payment = order['pago'] as Map<String, dynamic>?;
                final items =
                    (order['items'] as List? ?? []).cast<Map<String, dynamic>>();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(order['folio']?.toString() ?? 'Pedido'),
                    subtitle: Text(
                      'Pago: ${order['estado_pago']} · Envío: ${order['estado_envio']}',
                    ),
                    trailing: Text(
                      '\$${(order['total'] as num).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Envío a ${order['nombre_dest']}: ${order['direccion']}'),
                      ),
                      const SizedBox(height: 8),
                      ...items.map(
                        (item) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['nombre']?.toString() ?? ''),
                          subtitle: Text('Cantidad: ${item['cantidad']}'),
                          trailing: Text(
                            '\$${(item['importe'] as num).toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                      if (payment != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pago ${payment['metodo']} · ${payment['estado']} · ref. ${payment['referencia']}',
                          ),
                        ),
                      if (order['estado_pago'] == 'pendiente' && payment == null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _paying.contains(id)
                                ? null
                                : () => _registerPayment(order),
                            icon: const Icon(Icons.payments_outlined),
                            label: Text(
                              _paying.contains(id)
                                  ? 'Enviando...'
                                  : 'Registrar pago',
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FeatureService _service = FeatureService();
  late Future<List<Map<String, dynamic>>> _orders;
  Map<String, dynamic> _user = const {};
  bool _argumentsRead = false;

  static const _paymentStatuses = ['pendiente', 'pagado', 'rechazado'];
  static const _shippingStatuses = [
    'confirmado',
    'preparacion',
    'enviado',
    'entregado',
    'cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _orders = _service.pedidosAdmin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _user = Map<String, dynamic>.from(args);
    _argumentsRead = true;
  }

  void _reload() => setState(() => _orders = _service.pedidosAdmin());

  Future<void> _update(
    Map<String, dynamic> order,
    String payment,
    String shipping,
  ) async {
    try {
      await _service.cambiarEstadoPedido(
        (order['id_ped'] as num).toInt(),
        payment,
        shipping,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado del pedido actualizado.')),
        );
        _reload();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el pedido: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administrar pedidos'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    drawer: AdminDrawer(usuario: _user, rutaActual: '/admin/orders'),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _orders,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('No se pudieron cargar: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) return const Center(child: Text('No hay pedidos.'));
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            var payment = order['estado_pago']?.toString() ?? 'pendiente';
            var shipping = order['estado_envio']?.toString() ?? 'confirmado';
            return Card(
              child: ExpansionTile(
                title: Text('${order['folio']} · \$${order['total']}'),
                subtitle: Text(
                  '${order['nombre_dest']} · ${order['direccion']}',
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatuses.contains(payment)
                        ? payment
                        : 'pendiente',
                    decoration: const InputDecoration(labelText: 'Estado de pago'),
                    items: _paymentStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => payment = value ?? payment,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _shippingStatuses.contains(shipping)
                        ? shipping
                        : 'confirmado',
                    decoration: const InputDecoration(labelText: 'Estado de envío'),
                    items: _shippingStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => shipping = value ?? shipping,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => _update(order, payment, shipping),
                      child: const Text('Guardar estado'),
                    ),
                  ),
                  ...((order['items'] as List? ?? [])
                      .cast<Map<String, dynamic>>()
                      .map(
                        (item) => ListTile(
                          dense: true,
                          title: Text(item['nombre']?.toString() ?? ''),
                          subtitle: Text('Cantidad: ${item['cantidad']}'),
                        ),
                      )),
                  if (order['pago'] is Map)
                    Text(
                      'Referencia: ${(order['pago'] as Map)['referencia']}',
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
