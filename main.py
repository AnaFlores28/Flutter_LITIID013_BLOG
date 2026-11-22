from contextlib import asynccontextmanager
from datetime import datetime, timedelta
import base64
import hashlib
import hmac
import json
import mimetypes
import os
from pathlib import Path
import secrets
import uuid

from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pwdlib import PasswordHash
from pwdlib.hashers.bcrypt import BcryptHasher
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import Base, engine, obtener_sesion
from models import (
    Blog,
    Carrito,
    CarritoItem,
    Comentario,
    Conversacion,
    Mensaje,
    Pago,
    Pedido,
    PedidoItem,
    Producto,
    Reaccion,
    Reporte,
    Sticker,
    Usuario,
    Valoracion,
)
from schemas import (
    BlogCrear,
    CarritoItemCrear,
    ComentarioCrear,
    ConversacionCrear,
    EstadoPedidoActualizar,
    LoginRequest,
    MensajeCrear,
    PagoCrear,
    PedidoCrear,
    PerfilActualizar,
    ProductoCrear,
    ReporteActualizar,
    ReporteCrear,
    UsuarioActualizar,
    UsuarioCrear,
)


BACKEND_DIR = Path(__file__).resolve().parent
WEB_ROOT = Path(
    os.getenv("SOUND_OAC_WEB_ROOT", r"C:\xampp\htdocs\sound_oac_mejorado")
).resolve()
WEB_UPLOAD_DIR = WEB_ROOT / "uploads"
DEFAULT_UPLOAD_DIR = (
    WEB_UPLOAD_DIR if WEB_UPLOAD_DIR.is_dir() else BACKEND_DIR / "uploads"
)
UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", str(DEFAULT_UPLOAD_DIR))).resolve()
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
TOKEN_SECRET = os.getenv("API_TOKEN_SECRET") or secrets.token_bytes(32)
TOKEN_LIFETIME = timedelta(days=7)
TIPOS_PUBLICACION = {"resena", "recomendacion", "noticia", "cronica"}
TIPOS_MEDIO = {"artista", "album"}
ESTADOS_PAGO = {"pendiente", "pagado", "rechazado"}
ESTADOS_ENVIO = {"confirmado", "preparacion", "enviado", "entregado", "cancelado"}
METODOS_PAGO = {"transferencia", "tarjeta", "efectivo"}
TIPOS_REPORTE = {"publicacion", "comentario", "usuario"}
ESTADOS_REPORTE = {"pendiente", "resuelto", "descartado"}
TIPOS_REACCION = {"like", "amor", "risa", "sorpresa", "palomitas"}
hasher = PasswordHash.recommended()
bcrypt_hasher = BcryptHasher()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="Sound OAC API", version="2.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


def _token(user_id: int) -> str:
    payload = base64.urlsafe_b64encode(
        json.dumps(
            {
                "sub": user_id,
                "exp": int((datetime.utcnow() + TOKEN_LIFETIME).timestamp()),
            },
            separators=(",", ":"),
        ).encode()
    ).decode().rstrip("=")
    signature = hmac.new(
        TOKEN_SECRET if isinstance(TOKEN_SECRET, bytes) else TOKEN_SECRET.encode(),
        payload.encode(),
        hashlib.sha256,
    ).digest()
    return payload + "." + base64.urlsafe_b64encode(signature).decode().rstrip("=")


def _user_response(user: Usuario) -> dict:
    return {
        "id_usr": user.id_usr,
        "nom_usr": user.nom_usr,
        "mail": user.mail,
        "dir_usr": user.dir_usr,
        "tip_usu": user.tip_usu,
        "estatus": user.estatus,
        "avatar": user.avatar,
        "bio": user.bio,
        "generos": user.generos,
        "tel": user.tel,
    }


def _verify_password(password: str, stored_hash: str) -> bool:
    try:
        if stored_hash.startswith(("$2a$", "$2b$", "$2y$")):
            normalized_hash = "$2b$" + stored_hash[4:] if stored_hash.startswith("$2y$") else stored_hash
            return bcrypt_hasher.verify(password, normalized_hash)
        return hasher.verify(password, stored_hash)
    except (ValueError, TypeError):
        return False


def _hash_password(password: str) -> str:
    if len(password.encode("utf-8")) > 72:
        raise HTTPException(status_code=422, detail="La contraseña no puede superar 72 bytes.")
    value = bcrypt_hasher.hash(password)
    return "$2y$" + value[4:] if value.startswith("$2b$") else value


def get_current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(obtener_sesion),
) -> Usuario:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Inicia sesión para continuar.")
    token = authorization[7:].strip()
    try:
        payload, signature = token.split(".", 1)
        secret = TOKEN_SECRET if isinstance(TOKEN_SECRET, bytes) else TOKEN_SECRET.encode()
        expected = base64.urlsafe_b64encode(
            hmac.new(secret, payload.encode(), hashlib.sha256).digest()
        ).decode().rstrip("=")
        if not hmac.compare_digest(signature, expected):
            raise ValueError("Invalid token signature")
        encoded_payload = payload + "=" * (-len(payload) % 4)
        token_data = json.loads(base64.urlsafe_b64decode(encoded_payload))
        if int(token_data["exp"]) < int(datetime.utcnow().timestamp()):
            raise ValueError("Expired token")
        user_id = int(token_data["sub"])
    except (ValueError, TypeError, KeyError, json.JSONDecodeError):
        raise HTTPException(status_code=401, detail="La sesión no es válida o expiró.")

    user = db.get(Usuario, user_id)
    if user is None or user.estatus != 1:
        raise HTTPException(status_code=401, detail="La cuenta no está disponible.")
    return user


def require_admin(user: Usuario = Depends(get_current_user)) -> Usuario:
    if user.tip_usu != 0:
        raise HTTPException(status_code=403, detail="Se requiere una cuenta de administrador.")
    return user


def _raise_not_found(entity: str):
    raise HTTPException(status_code=404, detail=f"{entity} no encontrado.")


def _public_user(user: Usuario) -> dict:
    return {
        "id_usr": user.id_usr,
        "nom_usr": user.nom_usr,
        "avatar": user.avatar,
        "bio": user.bio,
        "generos": user.generos,
    }


def _blog_response(db: Session, blog: Blog) -> dict:
    author = db.get(Usuario, blog.usr_id)
    average, total = db.execute(
        select(func.avg(Valoracion.estrellas), func.count(Valoracion.id_val)).where(
            Valoracion.blog_id == blog.id_blog
        )
    ).one()
    return {
        "id_blog": blog.id_blog,
        "usr_id": blog.usr_id,
        "titulo": blog.titulo,
        "contenido": blog.contenido,
        "descripcion": blog.contenido,
        "desc": blog.contenido,
        "img": blog.img,
        "imagen_url": f"/uploads/publicaciones/{blog.img}" if blog.img else None,
        "tags": blog.tags,
        "tipo": blog.tipo,
        "medio_tipo": blog.medio_tipo,
        "medio_nombre": blog.medio_nombre,
        "genero": blog.genero,
        "estatus": blog.estatus,
        "fecha": blog.fecha,
        "autor": _public_user(author) if author else None,
        "promedio": float(average) if average is not None else None,
        "total_valoraciones": int(total or 0),
    }


def _comment_response(db: Session, comment: Comentario) -> dict:
    user = db.get(Usuario, comment.usr_id)
    reactions = db.execute(
        select(Reaccion.tipo, func.count(Reaccion.id_rea))
        .where(Reaccion.com_id == comment.id_com)
        .group_by(Reaccion.tipo)
    ).all()
    return {
        "id_com": comment.id_com,
        "comentario": comment.comentario,
        "fecha": comment.fecha,
        "estatus": comment.estatus,
        "usr_id": comment.usr_id,
        "blog_id": comment.blog_id,
        "padre_id": comment.padre_id,
        "nom_usr": user.nom_usr if user else "",
        "avatar": user.avatar if user else None,
        "reacciones": {kind: count for kind, count in reactions},
    }


def _product_response(product: Producto) -> dict:
    return {
        "id_prod": product.id_prod,
        "nombre": product.nombre,
        "descripcion": product.descripcion,
        "precio": float(product.precio),
        "img": product.img,
        "imagen_url": f"/uploads/productos/{product.img}" if product.img else None,
        "categoria": product.categoria,
        "stock": product.stock,
        "estatus": product.estatus,
    }


def _order_response(db: Session, order: Pedido) -> dict:
    items = db.scalars(select(PedidoItem).where(PedidoItem.ped_id == order.id_ped)).all()
    payment = db.scalar(
        select(Pago)
        .where(Pago.ped_id == order.id_ped)
        .order_by(Pago.fecha.desc(), Pago.id_pago.desc())
        .limit(1)
    )
    return {
        "id_ped": order.id_ped,
        "folio": order.folio,
        "usr_id": order.usr_id,
        "subtotal": float(order.subtotal),
        "envio": float(order.envio),
        "total": float(order.total),
        "nombre_dest": order.nombre_dest,
        "tel": order.tel,
        "direccion": order.direccion,
        "colonia": order.colonia,
        "ciudad": order.ciudad,
        "estado": order.estado,
        "cp": order.cp,
        "estado_pago": order.estado_pago,
        "estado_envio": order.estado_envio,
        "fecha": order.fecha,
        "items": [
            {
                "id_item": item.id_item,
                "nombre": item.nombre,
                "precio": float(item.precio),
                "cantidad": item.cantidad,
                "importe": float(item.precio) * item.cantidad,
            }
            for item in items
        ],
        "pago": (
            {
                "referencia": payment.referencia,
                "metodo": payment.metodo,
                "estado": payment.estado,
                "monto": float(payment.monto),
                "fecha": payment.fecha,
            }
            if payment
            else None
        ),
    }


def _get_cart(db: Session, user_id: int) -> Carrito:
    cart = db.scalar(select(Carrito).where(Carrito.usr_id == user_id))
    if cart is None:
        cart = Carrito(usr_id=user_id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart


def _cart_response(db: Session, cart: Carrito) -> dict:
    rows = db.execute(
        select(CarritoItem, Producto)
        .join(Producto, Producto.id_prod == CarritoItem.prod_id)
        .where(CarritoItem.car_id == cart.id_car)
        .order_by(CarritoItem.id_item)
    ).all()
    items = []
    for cart_item, product in rows:
        items.append(
            {
                "id_item": cart_item.id_item,
                "producto": _product_response(product),
                "cantidad": cart_item.cantidad,
                "importe": float(product.precio) * cart_item.cantidad,
            }
        )
    subtotal = sum(item["importe"] for item in items)
    envio = 0 if subtotal >= 500 or subtotal == 0 else 99
    return {
        "id_car": cart.id_car,
        "items": items,
        "subtotal": subtotal,
        "envio": envio,
        "total": subtotal + envio,
    }


@app.get("/")
def inicio():
    return {"mensaje": "Sound OAC API funcionando correctamente"}


@app.post("/login")
def iniciar_sesion(datos: LoginRequest, db: Session = Depends(obtener_sesion)):
    user = db.scalar(select(Usuario).where(Usuario.mail == datos.mail.strip().lower()))
    if user is None or user.estatus != 1 or not _verify_password(datos.password, user.pass_hash):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos.")
    return {"access_token": _token(user.id_usr), "token_type": "bearer", "usuario": _user_response(user), **_user_response(user)}


@app.post("/usuarios", status_code=201)
def crear_usuario(datos: UsuarioCrear, db: Session = Depends(obtener_sesion)):
    if len(datos.password.encode("utf-8")) > 72:
        raise HTTPException(status_code=422, detail="La contraseña no puede superar 72 bytes.")
    user = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=_hash_password(datos.password),
        dir_usr=datos.dir_usr,
        tip_usu=1,
        estatus=1,
    )
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo ya está registrado.")
    return _user_response(user)


@app.get("/me")
def obtener_usuario_actual(user: Usuario = Depends(get_current_user)):
    return _user_response(user)


@app.get("/usuarios/buscar")
def buscar_usuarios(
    q: str,
    db: Session = Depends(obtener_sesion),
    _user: Usuario = Depends(get_current_user),
):
    query = q.strip()[:80]
    if len(query) < 2:
        return []
    users = db.scalars(
        select(Usuario)
        .where(Usuario.estatus == 1, Usuario.nom_usr.like(f"%{query}%"))
        .order_by(Usuario.nom_usr)
        .limit(20)
    ).all()
    return [_public_user(user) for user in users]


@app.get("/usuarios")
def listar_usuarios(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    return [_user_response(user) for user in db.scalars(select(Usuario).order_by(Usuario.fecha_reg.desc())).all()]


@app.get("/usuarios/{usuario_id}")
def obtener_perfil(
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
    _user: Usuario = Depends(get_current_user),
):
    user = db.get(Usuario, usuario_id)
    if user is None or user.estatus != 1:
        _raise_not_found("Usuario")
    posts = db.scalars(
        select(Blog).where(Blog.usr_id == user.id_usr, Blog.estatus == 1).order_by(Blog.fecha.desc())
    ).all()
    return {**_public_user(user), "publicaciones": [_blog_response(db, post) for post in posts]}


@app.put("/perfil")
def actualizar_perfil(
    datos: PerfilActualizar,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    user.nom_usr = datos.nom_usr.strip()
    user.dir_usr = datos.dir_usr
    user.bio = datos.bio
    user.generos = datos.generos
    user.tel = datos.tel
    db.commit()
    db.refresh(user)
    return _user_response(user)


@app.put("/usuarios/{usuario_id}")
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_sesion),
    current: Usuario = Depends(get_current_user),
):
    if current.tip_usu != 0 and current.id_usr != usuario_id:
        raise HTTPException(status_code=403, detail="No puedes modificar esta cuenta.")
    user = db.get(Usuario, usuario_id)
    if user is None:
        _raise_not_found("Usuario")
    user.nom_usr = datos.nom_usr.strip()
    user.mail = datos.mail.strip().lower()
    user.dir_usr = datos.dir_usr
    if current.tip_usu == 0:
        if datos.tip_usu not in (0, 1):
            raise HTTPException(status_code=422, detail="El rol seleccionado no es válido.")
        if datos.estatus is not None:
            user.estatus = datos.estatus
        user.tip_usu = datos.tip_usu
    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo ya está registrado.")
    return _user_response(user)


@app.delete("/usuarios/{usuario_id}", status_code=204)
def eliminar_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
    admin: Usuario = Depends(require_admin),
):
    if admin.id_usr == usuario_id:
        raise HTTPException(status_code=409, detail="No puedes eliminar tu propia cuenta de administrador.")
    user = db.get(Usuario, usuario_id)
    if user is None:
        _raise_not_found("Usuario")
    db.delete(user)
    db.commit()


@app.post("/admin/usuarios", status_code=201)
def crear_usuario_admin(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    role = datos.tip_usu if datos.tip_usu in (0, 1) else 1
    user = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=_hash_password(datos.password),
        dir_usr=datos.dir_usr,
        tip_usu=role,
        estatus=1,
    )
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo ya está registrado.")
    return _user_response(user)


@app.get("/blog")
def listar_blog(
    db: Session = Depends(obtener_sesion),
):
    posts = db.scalars(select(Blog).where(Blog.estatus == 1).order_by(Blog.fecha.desc())).all()
    return [_blog_response(db, post) for post in posts]


@app.get("/blog/{blog_id}")
def obtener_blog(blog_id: int, db: Session = Depends(obtener_sesion)):
    post = db.get(Blog, blog_id)
    if post is None or post.estatus != 1:
        _raise_not_found("Publicación")
    return _blog_response(db, post)


@app.post("/blog", status_code=201)
def crear_blog(
    datos: BlogCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    if datos.tipo not in TIPOS_PUBLICACION or datos.medio_tipo not in TIPOS_MEDIO:
        raise HTTPException(status_code=422, detail="El tipo de publicación o medio no es válido.")
    post = Blog(
        usr_id=user.id_usr,
        titulo=datos.titulo.strip(),
        contenido=datos.contenido.strip(),
        tags=datos.tags,
        tipo=datos.tipo,
        medio_tipo=datos.medio_tipo,
        medio_nombre=datos.medio_nombre.strip(),
        genero=datos.genero.strip(),
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return _blog_response(db, post)


@app.post("/blog/imagen", status_code=201)
async def crear_blog_con_imagen(
    titulo: str = Form(...),
    contenido: str = Form(...),
    medio_nombre: str = Form(...),
    genero: str = Form(...),
    tipo: str = Form("resena"),
    medio_tipo: str = Form("artista"),
    tags: str | None = Form(default=None),
    imagen: UploadFile = File(...),
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    if tipo not in TIPOS_PUBLICACION or medio_tipo not in TIPOS_MEDIO:
        raise HTTPException(status_code=422, detail="El tipo de publicación o medio no es válido.")
    filename = await _save_upload(imagen, "publicaciones")
    post = Blog(
        usr_id=user.id_usr,
        titulo=titulo.strip(),
        contenido=contenido.strip(),
        img=filename,
        tags=tags,
        tipo=tipo,
        medio_tipo=medio_tipo,
        medio_nombre=medio_nombre.strip(),
        genero=genero.strip(),
    )
    db.add(post)
    try:
        db.commit()
        db.refresh(post)
    except Exception:
        db.rollback()
        (UPLOAD_DIR / "publicaciones" / filename).unlink(missing_ok=True)
        raise
    return _blog_response(db, post)


@app.put("/blog/{blog_id}")
def actualizar_blog(
    blog_id: int,
    datos: BlogCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    post = db.get(Blog, blog_id)
    if post is None:
        _raise_not_found("Publicación")
    if user.tip_usu != 0 and post.usr_id != user.id_usr:
        raise HTTPException(status_code=403, detail="No puedes editar esta publicación.")
    if datos.tipo not in TIPOS_PUBLICACION or datos.medio_tipo not in TIPOS_MEDIO:
        raise HTTPException(status_code=422, detail="El tipo de publicación o medio no es válido.")
    for field in ("titulo", "contenido", "tags", "tipo", "medio_tipo", "medio_nombre", "genero"):
        value = getattr(datos, field)
        setattr(post, field, value.strip() if isinstance(value, str) and field != "tags" else value)
    db.commit()
    db.refresh(post)
    return _blog_response(db, post)


@app.delete("/blog/{blog_id}", status_code=204)
def eliminar_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    post = db.get(Blog, blog_id)
    if post is None:
        _raise_not_found("Publicación")
    if user.tip_usu != 0 and post.usr_id != user.id_usr:
        raise HTTPException(status_code=403, detail="No puedes eliminar esta publicación.")
    post.estatus = 0
    db.commit()


async def _save_upload(file: UploadFile, folder: str) -> str:
    extension = Path(file.filename or "").suffix.lower()
    allowed = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}
    if extension not in allowed:
        raise HTTPException(status_code=400, detail="Formato de imagen no permitido.")
    content = await file.read(5 * 1024 * 1024 + 1)
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="La imagen no puede superar 5 MB.")
    if file.content_type and file.content_type not in (allowed[extension], "application/octet-stream"):
        raise HTTPException(status_code=400, detail="El contenido no coincide con el formato de imagen.")
    destination_dir = UPLOAD_DIR / folder
    destination_dir.mkdir(parents=True, exist_ok=True)
    filename = uuid.uuid4().hex + extension
    (destination_dir / filename).write_bytes(content)
    return filename


@app.get("/blog/{blog_id}/comentarios")
def listar_comentarios_blog(blog_id: int, db: Session = Depends(obtener_sesion)):
    post = db.get(Blog, blog_id)
    if post is None or post.estatus != 1:
        _raise_not_found("Publicación")
    comments = db.scalars(
        select(Comentario)
        .where(Comentario.blog_id == blog_id, Comentario.estatus == 1)
        .order_by(Comentario.fecha)
    ).all()
    return [_comment_response(db, comment) for comment in comments]


@app.get("/comentarios")
def listar_comentarios(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    comments = db.scalars(select(Comentario).order_by(Comentario.fecha.desc())).all()
    return [_comment_response(db, comment) for comment in comments]


@app.post("/comentarios", status_code=201)
def crear_comentario(
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    post = db.get(Blog, datos.blog_id)
    if post is None or post.estatus != 1:
        _raise_not_found("Publicación")
    if datos.sticker_id is not None and db.get(Sticker, datos.sticker_id) is None:
        _raise_not_found("Sticker")
    if datos.padre_id is not None:
        parent = db.get(Comentario, datos.padre_id)
        if parent is None or parent.blog_id != datos.blog_id or parent.estatus != 1:
            raise HTTPException(status_code=404, detail="Comentario al que respondes no encontrado.")
    comment = Comentario(
        comentario=datos.comentario.strip(),
        sticker_id=datos.sticker_id,
        usr_id=user.id_usr,
        blog_id=datos.blog_id,
        padre_id=datos.padre_id,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    return _comment_response(db, comment)


@app.post("/comentarios/{comment_id}/reacciones")
def alternar_reaccion(
    comment_id: int,
    tipo: str,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    if tipo not in TIPOS_REACCION:
        raise HTTPException(status_code=422, detail="El tipo de reacción no es válido.")
    comment = db.get(Comentario, comment_id)
    if comment is None or comment.estatus != 1:
        _raise_not_found("Comentario")
    existing = db.scalar(
        select(Reaccion).where(
            Reaccion.usr_id == user.id_usr,
            Reaccion.com_id == comment_id,
            Reaccion.tipo == tipo,
        )
    )
    if existing:
        db.delete(existing)
        active = False
    else:
        db.add(Reaccion(usr_id=user.id_usr, com_id=comment_id, tipo=tipo))
        active = True
    db.commit()
    return {"activa": active, **_comment_response(db, comment)["reacciones"]}


@app.put("/admin/publicaciones/{blog_id}")
def moderar_publicacion(
    blog_id: int,
    estatus: int,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    if estatus not in (0, 1):
        raise HTTPException(status_code=422, detail="El estado debe ser 0 u 1.")
    post = db.get(Blog, blog_id)
    if post is None:
        _raise_not_found("Publicación")
    post.estatus = estatus
    db.commit()
    return _blog_response(db, post)


@app.put("/admin/comentarios/{comment_id}")
def moderar_comentario(
    comment_id: int,
    estatus: int,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    if estatus not in (0, 1):
        raise HTTPException(status_code=422, detail="El estado debe ser 0 u 1.")
    comment = db.get(Comentario, comment_id)
    if comment is None:
        _raise_not_found("Comentario")
    comment.estatus = estatus
    db.commit()
    return _comment_response(db, comment)


@app.get("/admin/publicaciones")
def listar_publicaciones_admin(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    posts = db.scalars(select(Blog).order_by(Blog.fecha.desc())).all()
    result = []
    for post in posts:
        author = db.get(Usuario, post.usr_id)
        total_comments = db.scalar(
            select(func.count(Comentario.id_com)).where(Comentario.blog_id == post.id_blog)
        )
        result.append(
            {
                **_blog_response(db, post),
                "nom_usr": author.nom_usr if author else "",
                "total_comentarios": int(total_comments or 0),
            }
        )
    return result


@app.get("/admin/comentarios")
def listar_comentarios_admin(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    comments = db.scalars(select(Comentario).order_by(Comentario.fecha.desc())).all()
    result = []
    for comment in comments:
        author = db.get(Usuario, comment.usr_id)
        post = db.get(Blog, comment.blog_id)
        result.append(
            {
                **_comment_response(db, comment),
                "titulo": post.titulo if post else "",
            }
        )
    return result


@app.get("/stickers")
def listar_stickers(db: Session = Depends(obtener_sesion)):
    return [
        {"id_stk": sticker.id_stk, "nombre": sticker.nombre, "archivo": sticker.archivo}
        for sticker in db.scalars(select(Sticker).order_by(Sticker.id_stk)).all()
    ]


@app.get("/conversaciones")
def listar_conversaciones(
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    conversations = db.scalars(
        select(Conversacion)
        .where(or_(Conversacion.usr1 == user.id_usr, Conversacion.usr2 == user.id_usr))
        .order_by(Conversacion.fecha_creacion.desc())
    ).all()
    result = []
    for conversation in conversations:
        other_id = conversation.usr2 if conversation.usr1 == user.id_usr else conversation.usr1
        other = db.get(Usuario, other_id)
        if other is None or other.estatus != 1:
            continue
        latest = db.scalar(
            select(Mensaje)
            .where(Mensaje.conv_id == conversation.id_conv)
            .order_by(Mensaje.fecha.desc(), Mensaje.id_msg.desc())
            .limit(1)
        )
        unread = db.scalar(
            select(func.count(Mensaje.id_msg)).where(
                Mensaje.conv_id == conversation.id_conv,
                Mensaje.usr_id != user.id_usr,
                Mensaje.leido == 0,
            )
        )
        result.append(
            {
                "id_conv": conversation.id_conv,
                "usuario": _public_user(other),
                "ultimo": latest.texto if latest else None,
                "ultima_fecha": latest.fecha if latest else conversation.fecha_creacion,
                "no_leidos": int(unread or 0),
            }
        )
    result.sort(key=lambda item: item["ultima_fecha"], reverse=True)
    return result


@app.post("/conversaciones", status_code=201)
def iniciar_conversacion(
    datos: ConversacionCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    if datos.usuario_id == user.id_usr:
        raise HTTPException(status_code=422, detail="No puedes conversar contigo mismo.")
    other = db.get(Usuario, datos.usuario_id)
    if other is None or other.estatus != 1:
        _raise_not_found("Usuario")
    first, second = sorted((user.id_usr, other.id_usr))
    conversation = db.scalar(
        select(Conversacion).where(Conversacion.usr1 == first, Conversacion.usr2 == second)
    )
    if conversation is None:
        conversation = Conversacion(usr1=first, usr2=second)
        db.add(conversation)
        try:
            db.commit()
            db.refresh(conversation)
        except IntegrityError:
            db.rollback()
            conversation = db.scalar(
                select(Conversacion).where(Conversacion.usr1 == first, Conversacion.usr2 == second)
            )
    return {"id_conv": conversation.id_conv, "usuario": _public_user(other)}


@app.get("/conversaciones/{conversation_id}/mensajes")
def listar_mensajes(
    conversation_id: int,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    conversation = db.get(Conversacion, conversation_id)
    if conversation is None or user.id_usr not in (conversation.usr1, conversation.usr2):
        _raise_not_found("Conversación")
    db.query(Mensaje).filter(
        Mensaje.conv_id == conversation_id,
        Mensaje.usr_id != user.id_usr,
        Mensaje.leido == 0,
    ).update({Mensaje.leido: 1}, synchronize_session=False)
    db.commit()
    messages = db.scalars(
        select(Mensaje).where(Mensaje.conv_id == conversation_id).order_by(Mensaje.fecha, Mensaje.id_msg)
    ).all()
    return [
        {
            "id_msg": message.id_msg,
            "conv_id": message.conv_id,
            "usr_id": message.usr_id,
            "texto": message.texto,
            "leido": message.leido,
            "fecha": message.fecha,
        }
        for message in messages
    ]


@app.post("/conversaciones/{conversation_id}/mensajes", status_code=201)
def enviar_mensaje(
    conversation_id: int,
    datos: MensajeCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    conversation = db.get(Conversacion, conversation_id)
    if conversation is None or user.id_usr not in (conversation.usr1, conversation.usr2):
        _raise_not_found("Conversación")
    message = Mensaje(conv_id=conversation_id, usr_id=user.id_usr, texto=datos.texto.strip())
    db.add(message)
    db.commit()
    db.refresh(message)
    return {
        "id_msg": message.id_msg,
        "conv_id": message.conv_id,
        "usr_id": message.usr_id,
        "texto": message.texto,
        "leido": message.leido,
        "fecha": message.fecha,
    }


@app.get("/productos")
def listar_productos(
    db: Session = Depends(obtener_sesion),
):
    products = db.scalars(
        select(Producto).where(Producto.estatus == 1).order_by(Producto.fecha.desc())
    ).all()
    return [_product_response(product) for product in products]


@app.get("/carrito")
def obtener_carrito(db: Session = Depends(obtener_sesion), user: Usuario = Depends(get_current_user)):
    return _cart_response(db, _get_cart(db, user.id_usr))


@app.post("/carrito/items")
def agregar_item_carrito(
    datos: CarritoItemCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    product = db.get(Producto, datos.producto_id)
    if product is None or product.estatus != 1:
        _raise_not_found("Producto")
    cart = _get_cart(db, user.id_usr)
    item = db.scalar(
        select(CarritoItem).where(CarritoItem.car_id == cart.id_car, CarritoItem.prod_id == product.id_prod)
    )
    quantity = datos.cantidad + (item.cantidad if item else 0)
    if quantity > product.stock:
        raise HTTPException(status_code=409, detail="La cantidad supera el inventario disponible.")
    if item:
        item.cantidad = quantity
    else:
        db.add(CarritoItem(car_id=cart.id_car, prod_id=product.id_prod, cantidad=quantity))
    db.commit()
    return _cart_response(db, cart)


@app.put("/carrito/items/{item_id}")
def actualizar_item_carrito(
    item_id: int,
    cantidad: int,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    if cantidad < 1 or cantidad > 99:
        raise HTTPException(status_code=422, detail="La cantidad debe estar entre 1 y 99.")
    cart = _get_cart(db, user.id_usr)
    item = db.scalar(
        select(CarritoItem).where(CarritoItem.id_item == item_id, CarritoItem.car_id == cart.id_car)
    )
    if item is None:
        _raise_not_found("Artículo del carrito")
    product = db.get(Producto, item.prod_id)
    if product is None or product.stock < cantidad:
        raise HTTPException(status_code=409, detail="No hay inventario suficiente.")
    item.cantidad = cantidad
    db.commit()
    return _cart_response(db, cart)


@app.delete("/carrito/items/{item_id}")
def quitar_item_carrito(
    item_id: int,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    cart = _get_cart(db, user.id_usr)
    item = db.scalar(
        select(CarritoItem).where(CarritoItem.id_item == item_id, CarritoItem.car_id == cart.id_car)
    )
    if item is None:
        _raise_not_found("Artículo del carrito")
    db.delete(item)
    db.commit()
    return _cart_response(db, cart)


@app.post("/pedidos", status_code=201)
def crear_pedido(
    datos: PedidoCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    cart = _get_cart(db, user.id_usr)
    rows = db.execute(
        select(CarritoItem, Producto)
        .join(Producto, Producto.id_prod == CarritoItem.prod_id)
        .where(CarritoItem.car_id == cart.id_car)
        .with_for_update()
    ).all()
    if not rows:
        raise HTTPException(status_code=409, detail="El carrito está vacío.")
    for cart_item, product in rows:
        if product.estatus != 1 or product.stock < cart_item.cantidad:
            raise HTTPException(status_code=409, detail=f"Inventario insuficiente para {product.nombre}.")
    subtotal = sum(float(product.precio) * item.cantidad for item, product in rows)
    shipping = 0 if subtotal >= 500 else 99
    order = Pedido(
        folio="PED-" + secrets.token_hex(5).upper(),
        usr_id=user.id_usr,
        subtotal=subtotal,
        envio=shipping,
        total=subtotal + shipping,
        nombre_dest=datos.nombre_dest.strip(),
        tel=datos.tel,
        direccion=datos.direccion.strip(),
        colonia=datos.colonia,
        ciudad=datos.ciudad,
        estado=datos.estado,
        cp=datos.cp,
    )
    db.add(order)
    db.flush()
    for cart_item, product in rows:
        db.add(
            PedidoItem(
                ped_id=order.id_ped,
                prod_id=product.id_prod,
                nombre=product.nombre,
                precio=product.precio,
                cantidad=cart_item.cantidad,
            )
        )
        product.stock -= cart_item.cantidad
        db.delete(cart_item)
    db.commit()
    db.refresh(order)
    return _order_response(db, order)


@app.post("/pedidos/{order_id}/pago", status_code=201)
def registrar_pago(
    order_id: int,
    datos: PagoCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    order = db.get(Pedido, order_id)
    if order is None or order.usr_id != user.id_usr:
        _raise_not_found("Pedido")
    if order.estado_pago != "pendiente":
        raise HTTPException(status_code=409, detail="El pedido no está disponible para registrar el pago.")
    if datos.metodo not in METODOS_PAGO:
        raise HTTPException(status_code=422, detail="El método de pago no es válido.")
    pending = db.scalar(
        select(Pago.id_pago).where(Pago.ped_id == order_id, Pago.estado == "pendiente").limit(1)
    )
    if pending:
        raise HTTPException(status_code=409, detail="Ya hay un pago pendiente de confirmación.")
    payment = Pago(
        ped_id=order_id,
        referencia=datos.referencia.strip(),
        metodo=datos.metodo,
        estado="pendiente",
        monto=order.total,
    )
    db.add(payment)
    db.commit()
    return {"id_pago": payment.id_pago, "estado": payment.estado}


@app.get("/pedidos")
def listar_pedidos(
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    orders = db.scalars(
        select(Pedido)
        .where(Pedido.usr_id == user.id_usr)
        .order_by(Pedido.fecha.desc())
    ).all()
    return [_order_response(db, order) for order in orders]


@app.get("/pedidos/{order_id}")
def obtener_pedido(
    order_id: int,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    order = db.get(Pedido, order_id)
    if order is None or (user.tip_usu != 0 and order.usr_id != user.id_usr):
        _raise_not_found("Pedido")
    return _order_response(db, order)


@app.get("/admin/pedidos")
def listar_pedidos_admin(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    orders = db.scalars(select(Pedido).order_by(Pedido.fecha.desc())).all()
    return [_order_response(db, order) for order in orders]


@app.put("/admin/pedidos/{order_id}")
def actualizar_estado_pedido(
    order_id: int,
    datos: EstadoPedidoActualizar,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    if datos.estado_pago not in ESTADOS_PAGO or datos.estado_envio not in ESTADOS_ENVIO:
        raise HTTPException(status_code=422, detail="El estado seleccionado no es válido.")
    order = db.scalar(select(Pedido).where(Pedido.id_ped == order_id).with_for_update())
    if order is None:
        _raise_not_found("Pedido")
    payment = db.scalar(
        select(Pago)
        .where(Pago.ped_id == order_id)
        .order_by(Pago.fecha.desc(), Pago.id_pago.desc())
        .limit(1)
        .with_for_update()
    )
    if datos.estado_pago == "pagado" and payment is None:
        raise HTTPException(status_code=409, detail="No se puede aprobar un pedido sin pago registrado.")
    order.estado_pago = datos.estado_pago
    order.estado_envio = datos.estado_envio
    if datos.estado_pago == "pagado" and payment is not None:
        db.query(Pago).filter(Pago.ped_id == order_id, Pago.id_pago != payment.id_pago).update(
            {Pago.estado: "rechazado"}, synchronize_session=False
        )
        payment.estado = "aprobado"
    elif datos.estado_pago == "rechazado":
        db.query(Pago).filter(Pago.ped_id == order_id).update(
            {Pago.estado: "rechazado"}, synchronize_session=False
        )
    db.commit()
    db.refresh(order)
    return _order_response(db, order)


@app.get("/admin/productos")
def listar_productos_admin(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    return [_product_response(item) for item in db.scalars(select(Producto).order_by(Producto.fecha.desc())).all()]


@app.post("/admin/productos", status_code=201)
def crear_producto(
    datos: ProductoCrear,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    if datos.categoria not in {"poster", "taza", "playera", "libreta", "accesorio"}:
        raise HTTPException(status_code=422, detail="La categoría no es válida.")
    product = Producto(
        nombre=datos.nombre.strip(),
        descripcion=datos.descripcion,
        precio=datos.precio,
        categoria=datos.categoria,
        stock=datos.stock,
        img=datos.img,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return _product_response(product)


@app.put("/admin/productos/{product_id}")
def actualizar_producto(
    product_id: int,
    datos: ProductoCrear,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    product = db.get(Producto, product_id)
    if product is None:
        _raise_not_found("Producto")
    if datos.categoria not in {"poster", "taza", "playera", "libreta", "accesorio"}:
        raise HTTPException(status_code=422, detail="La categoría no es válida.")
    for field in ("nombre", "descripcion", "precio", "categoria", "stock", "img"):
        setattr(product, field, getattr(datos, field))
    product.nombre = product.nombre.strip()
    db.commit()
    db.refresh(product)
    return _product_response(product)


@app.delete("/admin/productos/{product_id}")
def desactivar_producto(
    product_id: int,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    product = db.get(Producto, product_id)
    if product is None:
        _raise_not_found("Producto")
    product.estatus = 0
    db.commit()
    return {"estatus": 0}


@app.post("/reportes", status_code=201)
def crear_reporte(
    datos: ReporteCrear,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    if datos.tipo not in TIPOS_REPORTE:
        raise HTTPException(status_code=422, detail="El tipo de reporte no es válido.")
    if datos.tipo == "publicacion":
        target = db.get(Blog, datos.ref_id)
    elif datos.tipo == "comentario":
        target = db.get(Comentario, datos.ref_id)
    else:
        target = db.get(Usuario, datos.ref_id)
    if target is None:
        _raise_not_found(datos.tipo.capitalize())
    report = Reporte(tipo=datos.tipo, ref_id=datos.ref_id, motivo=datos.motivo.strip(), usr_id=user.id_usr)
    db.add(report)
    db.commit()
    db.refresh(report)
    return {"id_rep": report.id_rep, "estatus": report.estatus}


@app.get("/admin/reportes")
def listar_reportes(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    reports = db.scalars(select(Reporte).order_by(Reporte.fecha.desc())).all()
    return [
        {
            "id_rep": report.id_rep,
            "tipo": report.tipo,
            "ref_id": report.ref_id,
            "motivo": report.motivo,
            "usr_id": report.usr_id,
            "estatus": report.estatus,
            "fecha": report.fecha,
        }
        for report in reports
    ]


@app.put("/admin/reportes/{report_id}")
def actualizar_reporte(
    report_id: int,
    datos: ReporteActualizar,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    if datos.estatus not in ESTADOS_REPORTE:
        raise HTTPException(status_code=422, detail="El estado del reporte no es válido.")
    report = db.get(Reporte, report_id)
    if report is None:
        _raise_not_found("Reporte")
    report.estatus = datos.estatus
    db.commit()
    return {"id_rep": report.id_rep, "estatus": report.estatus}


@app.get("/admin/resumen")
def resumen_admin(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(require_admin),
):
    return {
        "usuarios": db.scalar(select(func.count(Usuario.id_usr))) or 0,
        "publicaciones": db.scalar(select(func.count(Blog.id_blog)).where(Blog.estatus == 1)) or 0,
        "comentarios": db.scalar(select(func.count(Comentario.id_com)).where(Comentario.estatus == 1)) or 0,
        "pedidos": db.scalar(select(func.count(Pedido.id_ped))) or 0,
        "reportes_pendientes": db.scalar(
            select(func.count(Reporte.id_rep)).where(Reporte.estatus == "pendiente")
        )
        or 0,
    }


@app.post("/blog/{blog_id}/valoraciones")
def valorar_publicacion(
    blog_id: int,
    estrellas: int,
    db: Session = Depends(obtener_sesion),
    user: Usuario = Depends(get_current_user),
):
    if estrellas < 1 or estrellas > 5:
        raise HTTPException(status_code=422, detail="La valoración debe ser de 1 a 5 estrellas.")
    post = db.get(Blog, blog_id)
    if post is None or post.estatus != 1:
        _raise_not_found("Publicación")
    rating = db.scalar(
        select(Valoracion).where(Valoracion.usr_id == user.id_usr, Valoracion.blog_id == blog_id)
    )
    if rating:
        rating.estrellas = estrellas
    else:
        db.add(Valoracion(usr_id=user.id_usr, blog_id=blog_id, estrellas=estrellas))
    db.commit()
    return _blog_response(db, post)
