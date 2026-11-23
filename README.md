# Sound OAC

Aplicación de comunidad musical con una API REST en FastAPI y un cliente móvil
hecho con Flutter. La API utiliza MySQL para usuarios, publicaciones,
comentarios, mensajería, tienda y pedidos.

## Requisitos

- Python 3.10 o posterior.
- MySQL 8 o compatible, iniciado localmente o accesible desde el equipo.
- Flutter SDK estable y sus dependencias de plataforma (Android Studio para
  emulador Android).
- Git, si se clona el repositorio.

## 1. Preparar la base de datos

Crea la base de datos en MySQL. La API crea las tablas que falten al iniciarse,
pero no crea la base de datos ni los usuarios de MySQL.

```sql
CREATE DATABASE sound_oac
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

Configura un usuario MySQL con permisos sobre `sound_oac` y guarda sus datos en
`backend_API/.env`:

```dotenv
DB_USER=tu_usuario
DB_PASSWORD=tu_contrasena
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=sound_oac

# Usa un valor secreto estable para que los tokens sigan siendo válidos
# después de reiniciar la API.
API_TOKEN_SECRET=cambia_esto_por_un_secreto_largo_y_aleatorio

API_HOST=0.0.0.0
API_PORT=8000
# Opcional: carpeta absoluta donde se guardarán las imágenes cargadas.
# UPLOAD_DIR=C:\ruta\de\tu\proyecto\uploads
```

No publiques el archivo `.env` ni incluyas contraseñas reales en el repositorio.

> `flutter_application_1/lib/db/db.sql` es un esquema de ejemplo antiguo: elimina
> y crea otra base de datos y no coincide con los modelos actuales del backend.
> No lo ejecutes para instalar esta versión.

## 2. Instalar y arrancar el backend

Desde la raíz del repositorio, abre PowerShell. Crea el entorno desde la raíz
para evitar que el archivo `backend_API/venv.py` se confunda con el módulo
estándar `venv`:

```powershell
python -m venv backend_API\venv
cd backend_API
python --version
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Crea `backend_API/.env` con las variables de la sección anterior y arranca la
API desde `backend_API`:

```powershell
python venv.py
```

También se puede iniciar directamente con Uvicorn:

```powershell
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

La comprobación local está en <http://127.0.0.1:8000/> y la documentación
interactiva de endpoints en <http://127.0.0.1:8000/docs>.

Para crear la primera cuenta, registra un usuario desde la app. Las cuentas
nuevas tienen el rol estándar; si se necesita un administrador inicial, cambia
su `tip_usu` a `0` en la tabla `usuario` con una cuenta autorizada de MySQL y
vuelve a iniciar sesión.

## 3. Instalar y ejecutar Flutter

En otra terminal, desde la raíz:

```powershell
cd flutter_application_1
flutter doctor
flutter pub get
flutter devices
flutter run
```

Para ejecutar en Chrome, si está disponible:

```powershell
flutter run -d chrome
```

## Conexión del móvil con la API

La URL predeterminada está en
[`api_client.dart`](flutter_application_1/lib/services/api_client.dart):

- Android Emulator: `http://10.0.2.2:8000`.
- Flutter Web: `http://localhost:8000`.
- Otros destinos: `http://127.0.0.1:8000`.

En un teléfono físico, `127.0.0.1` apunta al propio teléfono. Cambia la URL
predeterminada en `ApiClient` por la dirección IP local del equipo que ejecuta
el backend, conecta ambos dispositivos a la misma red y permite el puerto
`8000` en el firewall.

## Pruebas y análisis

Desde `flutter_application_1`:

```powershell
flutter test
flutter analyze
```

Para comprobar la sintaxis de los módulos del backend desde `backend_API`:

```powershell
python -m compileall main.py database.py models.py schemas.py venv.py
```

## Estructura principal

- `backend_API/`: API FastAPI, modelos SQLAlchemy y validación de datos.
- `flutter_application_1/lib/`: pantallas, widgets, modelos y servicios Flutter.
- `flutter_application_1/test/`: pruebas del cliente móvil.
