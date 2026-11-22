import 'package:flutter/material.dart';

import 'screens/login_user_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_user_page.dart';
import 'screens/users_page.dart';
import 'screens/blog_page.dart';
import 'screens/mapa_page.dart';
import 'screens/store_page.dart';
import 'screens/messages_page.dart';
import 'screens/orders_page.dart';
import 'screens/admin_moderation_page.dart';
import 'screens/admin_tools_page.dart';

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sound OAC',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F1E9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD93D),
          primary: const Color(0xFF4F200D),
          secondary: const Color(0xFFFF9A00),
          surface: const Color(0xFFFFFDFA),
          onSurface: const Color(0xFF4F200D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F1E9),
          foregroundColor: Color(0xFF4F200D),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFDFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFFFDFA),
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/users': (context) => const UsersPage(),
        '/blog': (context) => const BlogPage(),
        '/add-blog': (context) => const CrearBlogForm(),
        '/profile': (context) => const ProfilePage(),
        '/mapa': (context) => const MapaPage(),
        '/store': (context) => const StorePage(),
        '/cart': (context) => const CartPage(),
        '/messages': (context) => const MessagesPage(),
        '/conversation': (context) => const ConversationPage(),
        '/orders': (context) => const OrdersPage(),
        '/admin/moderation': (context) => const AdminModerationPage(),
        '/admin/orders': (context) => const AdminOrdersPage(),
        '/admin/tools': (context) => const AdminToolsPage(),
      },
    );
  }
}
