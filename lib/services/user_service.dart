import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  Future<List<UserModel>> obtenerUsuarios() async {
    final datos = await ApiClient.get('/usuarios');
    if (datos is! List) throw Exception('La lista de usuarios no es válida.');
    return datos
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> agregarUsuario(UserModel usuario) async {
    final path = ApiClient.accessToken == null ? '/usuarios' : '/admin/usuarios';
    final datos = await ApiClient.send('POST', path, body: usuario.toJsonCrear());
    return UserModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<UserModel> actualizarUsuario(UserModel usuario) async {
    final datos = await ApiClient.send(
      'PUT',
      '/usuarios/${usuario.id}',
      body: {
        'nom_usr': usuario.nombre,
        'mail': usuario.correo,
        'dir_usr': usuario.direccion,
        'tip_usu': usuario.tipoUsuario,
      },
    );
    return UserModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarUsuario(int id) async {
    await ApiClient.send('DELETE', '/usuarios/$id');
  }
}