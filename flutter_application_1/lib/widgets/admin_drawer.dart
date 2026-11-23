import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// Menú de navegación que muestra opciones comunes y administrativas por rol.
class AdminDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String rutaActual;

  const AdminDrawer({
    super.key,
    required this.usuario,
    required this.rutaActual,
  });

  bool get esAdmin => (usuario['tip_usu'] as num?)?.toInt() == 0;
  String get nombre => usuario['nom_usr']?.toString() ?? 'Sound OAC';
  String get correo => usuario['mail']?.toString() ?? '';

  /// Abre la pantalla solicitada y conserva los datos de la sesión en la ruta.
  void _navegar(BuildContext context, String ruta) {
    Navigator.pop(context);
    if (ruta == rutaActual) return;
    if (ruta == '/add-blog') {
      Navigator.pushNamed(context, ruta, arguments: usuario);
      return;
    }
    Navigator.pushReplacementNamed(context, ruta, arguments: usuario);
  }

  /// Elimina el token local y regresa al inicio de sesión.
  void _cerrarSesion(BuildContext context) {
    ApiClient.accessToken = null;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// Construye la lista de navegación con las opciones permitidas al usuario.
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF4F200D)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFFFFD93D),
                child: Icon(
                  esAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: const Color(0xFF4F200D),
                  size: 32,
                ),
              ),
              accountName: Text(nombre),
              accountEmail: Text(correo),
            ),
            _opcion(context, Icons.home_outlined, 'Comunidad', '/blog'),
            _opcion(context, Icons.storefront_outlined, 'Tienda', '/store'),
            _opcion(context, Icons.forum_outlined, 'Mensajes', '/messages'),
            _opcion(
              context,
              Icons.receipt_long_outlined,
              'Mis pedidos',
              '/orders',
            ),
            _opcion(
              context,
              Icons.account_circle_outlined,
              'Mi perfil',
              '/profile',
            ),
            if (esAdmin) ...[
              const Divider(),
              const ListTile(
                title: Text(
                  'Administración',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _opcion(
                context,
                Icons.people_alt_outlined,
                'Gestión de usuarios',
                '/users',
              ),
              _opcion(
                context,
                Icons.person_add_alt_1,
                'Registrar usuario',
                '/register',
              ),
              _opcion(context, Icons.post_add, 'Agregar blog', '/add-blog'),
              _opcion(
                context,
                Icons.rule_folder_outlined,
                'Moderación',
                '/admin/moderation',
              ),
              _opcion(
                context,
                Icons.local_shipping_outlined,
                'Administrar pedidos',
                '/admin/orders',
              ),
              _opcion(
                context,
                Icons.dashboard_outlined,
                'Herramientas',
                '/admin/tools',
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _cerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Crea un elemento de menú e indica si corresponde a la ruta activa.
  Widget _opcion(
    BuildContext context,
    IconData icono,
    String titulo,
    String ruta,
  ) {
    final seleccionado = ruta == rutaActual;
    return ListTile(
      leading: Icon(
        icono,
        color: seleccionado ? const Color(0xFF4F200D) : null,
      ),
      title: Text(titulo),
      selected: seleccionado,
      onTap: () => _navegar(context, ruta),
    );
  }
}
