from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)

from database import Base


class Usuario(Base):
    __tablename__ = "usuario"

    id_usr = Column(Integer, primary_key=True, index=True)
    nom_usr = Column(String(100), nullable=False)
    mail = Column(String(150), unique=True, nullable=False)
    pass_hash = Column("pass", String(255), nullable=False)
    avatar = Column(String(255))
    bio = Column(String(500))
    generos = Column(String(255))
    dir_usr = Column(String(255))
    tel = Column(String(20))
    tip_usu = Column(Integer, nullable=False, default=1)
    estatus = Column(Integer, nullable=False, default=1)
    fecha_reg = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Blog(Base):
    __tablename__ = "blog"

    id_blog = Column(Integer, primary_key=True, index=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    titulo = Column(String(200), nullable=False)
    contenido = Column(Text, nullable=False)
    img = Column(String(255))
    tags = Column(String(255))
    tipo = Column(String(20), nullable=False, default="resena")
    medio_tipo = Column(String(20), nullable=False, default="artista")
    medio_nombre = Column(String(150), nullable=False)
    genero = Column(String(80), nullable=False)
    spoilers = Column(Integer, nullable=False, default=0)
    estatus = Column(Integer, nullable=False, default=1)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Valoracion(Base):
    __tablename__ = "valoracion"

    id_val = Column(Integer, primary_key=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    blog_id = Column(Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), nullable=False)
    estrellas = Column(Integer, nullable=False)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Sticker(Base):
    __tablename__ = "sticker"

    id_stk = Column(Integer, primary_key=True)
    nombre = Column(String(50), nullable=False)
    archivo = Column(String(255), nullable=False)


class Comentario(Base):
    __tablename__ = "comentarios"

    id_com = Column(Integer, primary_key=True, index=True)
    comentario = Column(String(1000), nullable=False)
    sticker_id = Column(Integer, ForeignKey("sticker.id_stk", ondelete="SET NULL"))
    spoiler = Column(Integer, nullable=False, default=0)
    estatus = Column(Integer, nullable=False, default=1)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    blog_id = Column(Integer, ForeignKey("blog.id_blog", ondelete="CASCADE"), nullable=False)
    padre_id = Column(Integer, ForeignKey("comentarios.id_com", ondelete="CASCADE"))
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Reaccion(Base):
    __tablename__ = "reaccion"

    id_rea = Column(Integer, primary_key=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    com_id = Column(Integer, ForeignKey("comentarios.id_com", ondelete="CASCADE"), nullable=False)
    tipo = Column(String(20), nullable=False)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Conversacion(Base):
    __tablename__ = "conversacion"

    id_conv = Column(Integer, primary_key=True)
    usr1 = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    usr2 = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    fecha_creacion = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Mensaje(Base):
    __tablename__ = "mensaje"

    id_msg = Column(Integer, primary_key=True)
    conv_id = Column(Integer, ForeignKey("conversacion.id_conv", ondelete="CASCADE"), nullable=False)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    texto = Column(String(1000), nullable=False)
    leido = Column(Integer, nullable=False, default=0)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Producto(Base):
    __tablename__ = "producto"

    id_prod = Column(Integer, primary_key=True)
    nombre = Column(String(150), nullable=False)
    descripcion = Column(Text)
    precio = Column(Numeric(10, 2), nullable=False)
    img = Column(String(255))
    categoria = Column(String(20), nullable=False)
    stock = Column(Integer, nullable=False, default=0)
    estatus = Column(Integer, nullable=False, default=1)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Carrito(Base):
    __tablename__ = "carrito"

    id_car = Column(Integer, primary_key=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False, unique=True)
    fecha_creacion = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class CarritoItem(Base):
    __tablename__ = "carrito_item"

    id_item = Column(Integer, primary_key=True)
    car_id = Column(Integer, ForeignKey("carrito.id_car", ondelete="CASCADE"), nullable=False)
    prod_id = Column(Integer, ForeignKey("producto.id_prod", ondelete="CASCADE"), nullable=False)
    cantidad = Column(Integer, nullable=False, default=1)


class Pedido(Base):
    __tablename__ = "pedido"

    id_ped = Column(Integer, primary_key=True)
    folio = Column(String(30), unique=True, nullable=False)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    subtotal = Column(Numeric(10, 2), nullable=False, default=0)
    envio = Column(Numeric(10, 2), nullable=False, default=0)
    total = Column(Numeric(10, 2), nullable=False, default=0)
    nombre_dest = Column(String(150), nullable=False)
    tel = Column(String(20))
    direccion = Column(String(255), nullable=False)
    colonia = Column(String(120))
    ciudad = Column(String(120))
    estado = Column(String(80))
    cp = Column(String(10))
    estado_pago = Column(String(20), nullable=False, default="pendiente")
    estado_envio = Column(String(20), nullable=False, default="confirmado")
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class PedidoItem(Base):
    __tablename__ = "pedido_item"

    id_item = Column(Integer, primary_key=True)
    ped_id = Column(Integer, ForeignKey("pedido.id_ped", ondelete="CASCADE"), nullable=False)
    prod_id = Column(Integer, ForeignKey("producto.id_prod"), nullable=False)
    nombre = Column(String(150), nullable=False)
    precio = Column(Numeric(10, 2), nullable=False)
    cantidad = Column(Integer, nullable=False)


class Pago(Base):
    __tablename__ = "pago"

    id_pago = Column(Integer, primary_key=True)
    ped_id = Column(Integer, ForeignKey("pedido.id_ped", ondelete="CASCADE"), nullable=False)
    referencia = Column(String(100), nullable=False)
    metodo = Column(String(20), nullable=False, default="transferencia")
    estado = Column(String(20), nullable=False, default="pendiente")
    monto = Column(Numeric(10, 2), nullable=False)
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())


class Reporte(Base):
    __tablename__ = "reporte"

    id_rep = Column(Integer, primary_key=True)
    tipo = Column(String(20), nullable=False)
    ref_id = Column(Integer, nullable=False)
    motivo = Column(String(500), nullable=False)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr", ondelete="CASCADE"), nullable=False)
    estatus = Column(String(20), nullable=False, default="pendiente")
    fecha = Column(DateTime, nullable=False, server_default=func.current_timestamp())
