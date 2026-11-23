import 'api_client.dart';

/// Valida credenciales y delega el inicio de sesión y registro a la API.
class AuthService {

  /// Devuelve un mensaje cuando falta el correo o la contraseña.
  String? validarLogin({
    required String usuario,
    required String password,
  }) {
    if (usuario.trim().isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y contraseña';
    }

    return null;
  }


  /// Verifica los datos básicos del formulario de registro.
  String? validarRegistro({
    required String nombre,
    required String correo,
    required String password,
    required String confirmarpassword,
  }) {
    if (nombre.isEmpty ||
        correo.isEmpty ||
        password.isEmpty ||
        confirmarpassword.isEmpty) {
      return 'Completa todos los campos';
    }


    if (!correo.contains('@')) {
      return 'Ingresa un correo válido';
    }


    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }


    if (password != confirmarpassword) {
      return 'Las contraseñas no coinciden';
    }


    return null;
  }


  /// Autentica la cuenta, guarda el token y devuelve los datos del usuario.
  Future<Map<String, dynamic>> autenticar({
    required String correo,
    required String password,
  }) async {
    final resultado = await ApiClient.send(
      'POST',
      '/login',
      authenticated: false,
      body: {
        'mail': correo.trim().toLowerCase(),
        'password': password,
      },
    );
    if (resultado is! Map<String, dynamic>) {
      throw Exception('La respuesta de inicio de sesión no es válida.');
    }
    final usuario = Map<String, dynamic>.from(
      (resultado['usuario'] as Map?)?.cast<String, dynamic>() ?? resultado,
    );
    final token = resultado['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('La API no devolvió una sesión válida.');
    }
    ApiClient.accessToken = token;
    usuario['access_token'] = token;
    return usuario;
  }


  /// Registra una cuenta estándar o una cuenta desde el panel de administración.
  Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String correo,
    required String password,
    required int tipoUsuario,
  }) async {
    final admin = ApiClient.accessToken != null;
    final datos = await ApiClient.send(
      'POST',
      admin ? '/admin/usuarios' : '/usuarios',
      authenticated: admin,
      body: {
        'nom_usr': nombre.trim(),
        'mail': correo.trim().toLowerCase(),
        'password': password,
        'tip_usu': tipoUsuario,
      },
    );
    if (datos is! Map<String, dynamic>) {
      throw Exception('La respuesta de registro no es válida.');
    }
    return datos;
  }
}