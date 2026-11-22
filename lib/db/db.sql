
DROP DATABASE IF EXISTS bd_aplicacion_movil;
CREATE DATABASE bd_aplicacion_movil
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bd_aplicacion_movil;

CREATE TABLE usuario (
    id_usr   INT AUTO_INCREMENT PRIMARY KEY,
    nom_usr  VARCHAR(100) NOT NULL,
    mail     VARCHAR(150) NOT NULL UNIQUE,
    pass     VARCHAR(255) NOT NULL,
    dir_usr  VARCHAR(200),
    tip_usu  INT NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE blog (
    id_blog  INT AUTO_INCREMENT PRIMARY KEY,
    titulo   VARCHAR(150) NOT NULL,
    `desc`   TEXT,
    img      VARCHAR(500),
    tags     VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE comentarios (
    id_com      INT AUTO_INCREMENT PRIMARY KEY,
    comentario  TEXT NOT NULL,
    fecha       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estatus     INT NOT NULL DEFAULT 1,
    usr_id      INT NOT NULL,
    blog_id     INT NOT NULL,

    CONSTRAINT fk_comentario_usuario
        FOREIGN KEY (usr_id)
        REFERENCES usuario(id_usr),

    CONSTRAINT fk_comentario_blog
        FOREIGN KEY (blog_id)
        REFERENCES blog(id_blog)
) ENGINE=InnoDB;


INSERT INTO usuario (nom_usr, mail, pass, dir_usr, tip_usu) VALUES
('Ángel Martínez', 'angel@correo.com', SHA2('angel123', 256), 'Querétaro, Qro.', 2),
('Ana Celia',    'ana@correo.com', SHA2('ana123', 256), 'Corregidora, Qro.', 1);

INSERT INTO blog (titulo, `desc`, img, tags) VALUES
('Cómo crear una app con Flutter',
 'Donec at ultricies elit. Etiam dictum lorem et lectus congue, eget posuere magna luctus.',
 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRPYoA8gDM_iAy6-f56NC3UaKiKEv5ReoyizhnRwmKLPexnFab6B8uWFufM&s=10',
 'Flutter'),

('Introducción a la inteligencia artificial',
 'Donec at ultricies elit. Etiam dictum lorem et lectus congue, eget posuere magna luctus.',
 'https://728015.fs1.hubspotusercontent-na1.net/hubfs/728015/MediaTek%20Assets/Images/Blog/La%20Revoluci%C3%B3n%20de%20la%20IA%20Generativa%20Creando%20Contenido%20Original.jpg',
 'IA'),

('Principios básicos de diseño UI',
 'Donec at ultricies elit. Etiam dictum lorem et lectus congue, eget posuere magna luctus.',
 'https://img.magnific.com/vector-gratis/fondo-espacio-trabajo-diseno-grafico_23-2147795837.jpg?semt=ais_hybrid&w=740&q=80',
 'Diseño'),

('Widgets esenciales en Flutter',
 'Donec at ultricies elit. Etiam dictum lorem et lectus congue, eget posuere magna luctus.',
 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQN6aU969RyAgnyKu7FZ_h1iFoXLcXWduUfj8ne7jVW9sd8wcXcjKZQESU&s=10',
 'Flutter'),

('Conectar Flutter con una API REST',
 'Donec at ultricies elit. Etiam dictum lorem et lectus congue, eget posuere magna luctus.',
 'https://picsum.photos/seed/apirest/800/400',
 'Flutter');

INSERT INTO comentarios (comentario, estatus, usr_id, blog_id) VALUES
('Lorem ipsum dolor sit amet, consectetur adipiscing elit.',              1, 1, 1),
('¿Aenean maximus, lectus sit amet pretium interdum?',          1, 2, 2),
('Curabitur consequat risus eu rhoncus viverra.',           1, 2, 3),
('Fusce justo sapien, rhoncus nec massa ut.',               1, 1, 4),
('Nulla venenatis condimentum dolor sed convallis.', 1, 2, 5);