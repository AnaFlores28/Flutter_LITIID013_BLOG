"""Esquemas Pydantic para validar entradas y salidas de la API."""

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    """Credenciales requeridas para iniciar sesión."""

    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=1, max_length=128)


class UsuarioCrear(BaseModel):
    """Datos necesarios para registrar una cuenta."""

    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8, max_length=72)
    dir_usr: str | None = Field(default=None, max_length=255)
    tip_usu: int = 1


class UsuarioActualizar(BaseModel):
    """Campos editables de una cuenta, incluidos los cambios administrativos."""

    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    dir_usr: str | None = Field(default=None, max_length=255)
    tip_usu: int | None = None
    estatus: int | None = Field(default=None, ge=0, le=1)


class UsuarioRespuesta(BaseModel):
    """Representación pública del perfil devuelta por la API."""

    id_usr: int
    nom_usr: str
    mail: str
    dir_usr: str | None
    tip_usu: int
    estatus: int
    avatar: str | None = None
    bio: str | None = None
    generos: str | None = None

    model_config = ConfigDict(from_attributes=True)


class PerfilActualizar(BaseModel):
    """Campos que el usuario puede modificar en su propio perfil."""

    nom_usr: str = Field(min_length=2, max_length=100)
    dir_usr: str | None = Field(default=None, max_length=255)
    bio: str | None = Field(default=None, max_length=500)
    generos: str | None = Field(default=None, max_length=255)
    tel: str | None = Field(default=None, max_length=20)


class BlogCrear(BaseModel):
    """Contenido y metadatos requeridos para crear o editar una publicación."""

    titulo: str = Field(min_length=2, max_length=200)
    contenido: str = Field(min_length=1)
    tags: str | None = Field(default=None, max_length=255)
    tipo: str = "resena"
    medio_tipo: str = "artista"
    medio_nombre: str = Field(min_length=1, max_length=150)
    genero: str = Field(min_length=1, max_length=80)


class ComentarioCrear(BaseModel):
    """Datos para publicar un comentario o una respuesta."""

    comentario: str = Field(min_length=1, max_length=1000)
    blog_id: int = Field(gt=0)
    sticker_id: int | None = None
    padre_id: int | None = None
    usr_id: int | None = None


class MensajeCrear(BaseModel):
    """Texto de un mensaje nuevo."""

    texto: str = Field(min_length=1, max_length=1000)


class ConversacionCrear(BaseModel):
    """Identificador de la otra persona para iniciar una conversación."""

    usuario_id: int = Field(gt=0)


class CarritoItemCrear(BaseModel):
    """Producto y cantidad que se agregan al carrito."""

    producto_id: int = Field(gt=0)
    cantidad: int = Field(default=1, ge=1, le=99)


class PedidoCrear(BaseModel):
    """Datos de destino necesarios para crear un pedido desde el carrito."""

    nombre_dest: str = Field(min_length=2, max_length=150)
    tel: str | None = Field(default=None, max_length=20)
    direccion: str = Field(min_length=3, max_length=255)
    colonia: str | None = Field(default=None, max_length=120)
    ciudad: str | None = Field(default=None, max_length=120)
    estado: str | None = Field(default=None, max_length=80)
    cp: str | None = Field(default=None, max_length=10)


class PagoCrear(BaseModel):
    """Referencia y método informados para registrar un pago."""

    referencia: str = Field(min_length=1, max_length=100)
    metodo: str = "transferencia"


class EstadoPedidoActualizar(BaseModel):
    """Estados de pago y envío asignados por administración."""

    estado_pago: str
    estado_envio: str


class ProductoCrear(BaseModel):
    """Campos de un producto que se crea o actualiza en la tienda."""

    nombre: str = Field(min_length=1, max_length=150)
    descripcion: str | None = None
    precio: float = Field(ge=0)
    categoria: str
    stock: int = Field(ge=0)
    img: str | None = None


class ReporteCrear(BaseModel):
    """Tipo, identificador y motivo de un reporte enviado por un usuario."""

    tipo: str
    ref_id: int = Field(gt=0)
    motivo: str = Field(min_length=3, max_length=500)


class ReporteActualizar(BaseModel):
    """Nuevo estado asignado a un reporte de moderación."""

    estatus: str
