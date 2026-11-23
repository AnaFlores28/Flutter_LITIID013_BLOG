import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/api_client.dart';

/// Verifica la resolución de imágenes de API y la pantalla inicial de acceso.
void main() {
  // Las rutas relativas apuntan al servidor y las absolutas se conservan.
  test('web media paths resolve through the API host', () {
    expect(
      ApiClient.assetUrl('/uploads/publicaciones/portada.jpg'),
      '${ApiClient.baseUrl}/uploads/publicaciones/portada.jpg',
    );
    expect(
      ApiClient.assetUrl('https://cdn.example.com/portada.jpg'),
      'https://cdn.example.com/portada.jpg',
    );
  });

  // La aplicación debe mostrar los controles esenciales de inicio de sesión.
  testWidgets('login screen renders Sound OAC sign-in', (tester) async {
    await tester.pumpWidget(const LoginApp());

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('INGRESAR'), findsOneWidget);
  });
}
