from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=1, max_length=128)


class UsuarioCrear(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8, max_length=72)
    dir_usr: str | None = Field(default=None, max_length=255)
    tip_usu: int = 1


class UsuarioActualizar(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    dir_usr: str | None = Field(default=None, max_length=255)
    tip_usu: int | None = None
    estatus: int | None = Field(default=None, ge=0, le=1)


class UsuarioRespuesta(BaseModel):
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
    nom_usr: str = Field(min_length=2, max_length=100)
    dir_usr: str | None = Field(default=None, max_length=255)
    bio: str | None = Field(default=None, max_length=500)
    generos: str | None = Field(default=None, max_length=255)
    tel: str | None = Field(default=None, max_length=20)


class BlogCrear(BaseModel):
    titulo: str = Field(min_length=2, max_length=200)
    contenido: str = Field(min_length=1)
    tags: str | None = Field(default=None, max_length=255)
    tipo: str = "resena"
    medio_tipo: str = "artista"
    medio_nombre: str = Field(min_length=1, max_length=150)
    genero: str = Field(min_length=1, max_length=80)


class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1, max_length=1000)
    blog_id: int = Field(gt=0)
    sticker_id: int | None = None
    padre_id: int | None = None
    usr_id: int | None = None


class MensajeCrear(BaseModel):
    texto: str = Field(min_length=1, max_length=1000)


class ConversacionCrear(BaseModel):
    usuario_id: int = Field(gt=0)


class CarritoItemCrear(BaseModel):
    producto_id: int = Field(gt=0)
    cantidad: int = Field(default=1, ge=1, le=99)


class PedidoCrear(BaseModel):
    nombre_dest: str = Field(min_length=2, max_length=150)
    tel: str | None = Field(default=None, max_length=20)
    direccion: str = Field(min_length=3, max_length=255)
    colonia: str | None = Field(default=None, max_length=120)
    ciudad: str | None = Field(default=None, max_length=120)
    estado: str | None = Field(default=None, max_length=80)
    cp: str | None = Field(default=None, max_length=10)


class PagoCrear(BaseModel):
    referencia: str = Field(min_length=1, max_length=100)
    metodo: str = "transferencia"


class EstadoPedidoActualizar(BaseModel):
    estado_pago: str
    estado_envio: str


class ProductoCrear(BaseModel):
    nombre: str = Field(min_length=1, max_length=150)
    descripcion: str | None = None
    precio: float = Field(ge=0)
    categoria: str
    stock: int = Field(ge=0)
    img: str | None = None


class ReporteCrear(BaseModel):
    tipo: str
    ref_id: int = Field(gt=0)
    motivo: str = Field(min_length=3, max_length=500)


class ReporteActualizar(BaseModel):
    estatus: str
