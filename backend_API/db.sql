CREATE DATABASE IF NOT EXISTS sound_oac
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
USE sound_oac;

CREATE TABLE usuario (
  id_usr INT AUTO_INCREMENT PRIMARY KEY,
  nom_usr VARCHAR(100) NOT NULL,
  mail VARCHAR(150) NOT NULL UNIQUE,
  pass VARCHAR(255) NOT NULL,
  avatar VARCHAR(255) DEFAULT NULL,
  bio VARCHAR(500) DEFAULT NULL,
  generos VARCHAR(255) DEFAULT NULL,
  dir_usr VARCHAR(255) DEFAULT NULL,
  tel VARCHAR(20) DEFAULT NULL,
  tip_usu TINYINT NOT NULL DEFAULT 1 COMMENT '0=admin, 1=usuario',
  estatus TINYINT NOT NULL DEFAULT 1,
  fecha_reg DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_usr_mail (mail),
  INDEX idx_usr_tip (tip_usu)
) ENGINE=InnoDB;

CREATE TABLE blog (
  id_blog INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  titulo VARCHAR(200) NOT NULL,
  contenido TEXT NOT NULL,
  img VARCHAR(255) DEFAULT NULL,
  tags VARCHAR(255) DEFAULT NULL,
  tipo ENUM('resena','recomendacion','noticia','cronica') NOT NULL DEFAULT 'resena',
  medio_tipo ENUM('artista','album') NOT NULL DEFAULT 'artista',
  medio_nombre VARCHAR(150) NOT NULL,
  genero VARCHAR(80) NOT NULL,
  estatus TINYINT NOT NULL DEFAULT 1,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_blog_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  INDEX idx_blog_usr (usr_id),
  INDEX idx_blog_genero (genero),
  INDEX idx_blog_tipo (tipo),
  INDEX idx_blog_fecha (fecha)
) ENGINE=InnoDB;

CREATE TABLE valoracion (
  id_val INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  blog_id INT NOT NULL,
  estrellas TINYINT NOT NULL CHECK (estrellas BETWEEN 1 AND 5),
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_valoracion (usr_id, blog_id),
  CONSTRAINT fk_val_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  CONSTRAINT fk_val_blog FOREIGN KEY (blog_id) REFERENCES blog(id_blog) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sticker (
  id_stk INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  archivo VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE comentarios (
  id_com INT AUTO_INCREMENT PRIMARY KEY,
  comentario VARCHAR(1000) NOT NULL,
  sticker_id INT DEFAULT NULL,
  estatus TINYINT NOT NULL DEFAULT 1,
  usr_id INT NOT NULL,
  blog_id INT NOT NULL,
  padre_id INT DEFAULT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_com_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  CONSTRAINT fk_com_blog FOREIGN KEY (blog_id) REFERENCES blog(id_blog) ON DELETE CASCADE,
  CONSTRAINT fk_com_sticker FOREIGN KEY (sticker_id) REFERENCES sticker(id_stk) ON DELETE SET NULL,
  CONSTRAINT fk_com_padre FOREIGN KEY (padre_id) REFERENCES comentarios(id_com) ON DELETE CASCADE,
  INDEX idx_com_blog (blog_id),
  INDEX idx_com_usr (usr_id),
  INDEX idx_com_padre (padre_id)
) ENGINE=InnoDB;

CREATE TABLE reaccion (
  id_rea INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL,
  com_id INT NOT NULL,
  tipo ENUM('like','amor','risa','sorpresa','palomitas') NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_reaccion (usr_id, com_id, tipo),
  CONSTRAINT fk_rea_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  CONSTRAINT fk_rea_com FOREIGN KEY (com_id) REFERENCES comentarios(id_com) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE conversacion (
  id_conv INT AUTO_INCREMENT PRIMARY KEY,
  usr1 INT NOT NULL,
  usr2 INT NOT NULL,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_conv_u1 FOREIGN KEY (usr1) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  CONSTRAINT fk_conv_u2 FOREIGN KEY (usr2) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  UNIQUE KEY uniq_conversacion (usr1, usr2)
) ENGINE=InnoDB;

CREATE TABLE mensaje (
  id_msg INT AUTO_INCREMENT PRIMARY KEY,
  conv_id INT NOT NULL,
  usr_id INT NOT NULL,
  texto VARCHAR(1000) NOT NULL,
  leido TINYINT(1) NOT NULL DEFAULT 0,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_msg_conv FOREIGN KEY (conv_id) REFERENCES conversacion(id_conv) ON DELETE CASCADE,
  CONSTRAINT fk_msg_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  INDEX idx_msg_conv (conv_id),
  INDEX idx_msg_fecha (fecha)
) ENGINE=InnoDB;

CREATE TABLE producto (
  id_prod INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
  img VARCHAR(255) DEFAULT NULL,
  categoria ENUM('poster','taza','playera','libreta','accesorio') NOT NULL,
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  estatus TINYINT NOT NULL DEFAULT 1,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_prod_cat (categoria),
  INDEX idx_prod_est (estatus)
) ENGINE=InnoDB;

CREATE TABLE carrito (
  id_car INT AUTO_INCREMENT PRIMARY KEY,
  usr_id INT NOT NULL UNIQUE,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_car_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE carrito_item (
  id_item INT AUTO_INCREMENT PRIMARY KEY,
  car_id INT NOT NULL,
  prod_id INT NOT NULL,
  cantidad INT NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  UNIQUE KEY uniq_item (car_id, prod_id),
  CONSTRAINT fk_item_car FOREIGN KEY (car_id) REFERENCES carrito(id_car) ON DELETE CASCADE,
  CONSTRAINT fk_item_prod FOREIGN KEY (prod_id) REFERENCES producto(id_prod) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pedido (
  id_ped INT AUTO_INCREMENT PRIMARY KEY,
  folio VARCHAR(30) NOT NULL UNIQUE,
  usr_id INT NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  envio DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  nombre_dest VARCHAR(150) NOT NULL,
  tel VARCHAR(20) DEFAULT NULL,
  direccion VARCHAR(255) NOT NULL,
  colonia VARCHAR(120) DEFAULT NULL,
  ciudad VARCHAR(120) DEFAULT NULL,
  estado VARCHAR(80) DEFAULT NULL,
  cp VARCHAR(10) DEFAULT NULL,
  estado_pago ENUM('pendiente','pagado','rechazado') NOT NULL DEFAULT 'pendiente',
  estado_envio ENUM('confirmado','preparacion','enviado','entregado','cancelado') NOT NULL DEFAULT 'confirmado',
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ped_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  INDEX idx_ped_usr (usr_id),
  INDEX idx_ped_estado (estado_pago)
) ENGINE=InnoDB;

CREATE TABLE pedido_item (
  id_item INT AUTO_INCREMENT PRIMARY KEY,
  ped_id INT NOT NULL,
  prod_id INT NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  cantidad INT NOT NULL,
  CONSTRAINT fk_item_ped FOREIGN KEY (ped_id) REFERENCES pedido(id_ped) ON DELETE CASCADE,
  CONSTRAINT fk_item_prod2 FOREIGN KEY (prod_id) REFERENCES producto(id_prod)
) ENGINE=InnoDB;

CREATE TABLE pago (
  id_pago INT AUTO_INCREMENT PRIMARY KEY,
  ped_id INT NOT NULL,
  referencia VARCHAR(100) NOT NULL,
  metodo ENUM('transferencia','tarjeta','efectivo') NOT NULL DEFAULT 'transferencia',
  estado ENUM('aprobado','rechazado','pendiente') NOT NULL DEFAULT 'pendiente',
  monto DECIMAL(10,2) NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pago_ped FOREIGN KEY (ped_id) REFERENCES pedido(id_ped) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE reporte (
  id_rep INT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('publicacion','comentario','usuario') NOT NULL,
  ref_id INT NOT NULL,
  motivo VARCHAR(500) NOT NULL,
  usr_id INT NOT NULL,
  estatus ENUM('pendiente','resuelto','descartado') NOT NULL DEFAULT 'pendiente',
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rep_usr FOREIGN KEY (usr_id) REFERENCES usuario(id_usr) ON DELETE CASCADE,
  INDEX idx_rep_estado (estatus),
  INDEX idx_rep_tipo (tipo, ref_id)
) ENGINE=InnoDB;

INSERT INTO sticker (nombre, archivo) VALUES
('Palomitas','palomitas.svg'),
('Corazon','corazon.svg'),
('Estrella','estrella.svg'),
('Aplauso','clap.svg');

INSERT INTO producto (nombre, descripcion, precio, categoria, stock) VALUES
('Poster Sound OAC','Poster impreso de 40 x 60 cm.',149.00,'poster',20),
('Taza Sound OAC','Taza ceramica de 350 ml.',179.00,'taza',15),
('Playera The Playlist','Playera de algodon, tallas S a XL.',299.00,'playera',25),
('Libreta de Resenas','Libreta con 120 paginas para escribir resenas.',129.00,'libreta',30);

INSERT INTO usuario
    (nom_usr, mail, pass, avatar, bio, generos, dir_usr, tel, tip_usu, estatus)
VALUES
    (
        'Admin',
        'admin@gmail.com',
        '$2y$10$d1PCvUqalhiqXHbJ09orp.G7..merZlstw2fE7pst9TMuYvIRH0/i',
        NULL,
        'Administrador de Butaca Digital',
        NULL,
        NULL,
        NULL,
        0,
        2
    ),
    (
        'Ana Celia',
        'anacelia@gmail.com',
        '$2y$10$d1PCvUqalhiqXHbJ09orp.G7..merZlstw2fE7pst9TMuYvIRH0/i',
        NULL,
        'Fan del cine y las series.',
        'Ciencia ficción, drama, terror',
        'Mi casa',
        '2722662441',
        1,
        1
    );