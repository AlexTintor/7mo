/*
Integrantes
-Alex Fernando Bojórquez Rojas
-Jesus Aldhair Sarabia Guzman
-Bryan Martin Zamudio Lizarraga
-Jesus Miguel Velarde Arce
-Christian David Bustamante Tolosa
*/


--  CREACIÓN DE BASE DE DATOS Y FILEGROUPS
--------------------------------------------------
CREATE DATABASE biblioteca_fin
    ON PRIMARY
    (
        NAME = 'biblioteca_primary',
        FILENAME = 'C:\s\biblioteca_primary.mdf',
        SIZE = 50MB,
        FILEGROWTH = 20MB
    ),
    FILEGROUP FG_DATOS
    (
        NAME = 'biblioteca_datos1',
        FILENAME = 'C:\s\biblioteca_datos1.ndf', 
        SIZE = 50MB,
        FILEGROWTH = 20MB
    ),
    FILEGROUP FG_IDX
    (
        NAME = 'biblioteca_idx1',
        FILENAME = 'C:\s\biblioteca_idx1.ndf', 
        SIZE = 50MB,
        FILEGROWTH = 20MB
    )
LOG ON
    (
        NAME = 'biblioteca_log',
        FILENAME = 'C:\s\biblioteca_log.ldf', 
        SIZE = 50MB,
        FILEGROWTH = 20MB
    )
GO

USE biblioteca_fin
GO

-- TABLAS Y PARTICIONAMIENTO
--------------------------------------------------

CREATE TABLE usuario
(
    usuario_no INT NOT NULL, 
    nombre NVARCHAR(50) NOT NULL,
    apellido NVARCHAR(50) NOT NULL,
    inicial NCHAR(1) NULL
) ON FG_DATOS
GO

CREATE TABLE adulto
(
    usuario_no INT NOT NULL,
    calle NVARCHAR(100) NOT NULL,
    codigopostal CHAR(5) NOT NULL,
    ciudad NVARCHAR(100) NOT NULL,
    estado NVARCHAR(50) NOT NULL,
    telefono CHAR(10) NULL, 
    fecha_exp DATE NOT NULL 
) ON FG_DATOS
GO

CREATE TABLE joven
(
    usuario_no INT NOT NULL,
    fechanacimiento DATE NOT NULL,
    adult_usuario_no INT NOT NULL
) ON FG_DATOS
GO

-- Tablas de Libros
CREATE TABLE titulo
(
    titulo_no INT NOT NULL,
    titulo NVARCHAR(100) NOT NULL,
    autor NVARCHAR(100) NOT NULL
) ON FG_DATOS
GO

CREATE TABLE descripcion_libro
(
    isbn VARCHAR(13) NOT NULL, 
    titulo_no INT NOT NULL,
    idioma NVARCHAR(20) NULL,
    pasta NVARCHAR(10) NULL,
    prestable CHAR(1) NULL 
) ON FG_DATOS
GO

CREATE TABLE copia
(
    isbn VARCHAR(13) NOT NULL,
    copy_no INT NOT NULL,
    titulo_no INT NOT NULL,
    en_prestamo CHAR(1) NOT NULL 
) ON FG_DATOS
GO


CREATE TABLE reservaciones
(
    isbn VARCHAR(13) NOT NULL,
    usuario_no INT NOT NULL,
    fecha_reserva DATE NULL
) ON FG_DATOS
GO

CREATE TABLE prestamo
(
    isbn VARCHAR(13) NOT NULL,
    copy_no INT NOT NULL,
    titulo_no INT NOT NULL,
    usuario_no INT NOT NULL,
    fecha_prestamo DATE NOT NULL,
    fecha_regreso DATE NOT NULL
) ON FG_DATOS
GO

-- Particionamiento para HISTORICO_PRESTAMO
CREATE PARTITION FUNCTION pf_prestamos_por_año (DATE)
AS RANGE RIGHT FOR VALUES (
    '2000-01-01', '2005-01-01', '2010-01-01', '2015-01-01', 
    '2020-01-01', '2025-01-01', '2030-01-01'
)
GO

CREATE PARTITION SCHEME ps_prestamos_por_año
AS PARTITION pf_prestamos_por_año
ALL TO (FG_DATOS)
GO

CREATE TABLE historico_prestamo (
    isbn VARCHAR(13) NOT NULL,
    copy_no INT NOT NULL,
    titulo_no INT NOT NULL,
    usuario_no INT NOT NULL,
    fecha_prestamo DATE NOT NULL,
    fecha_regreso DATE NOT NULL,
    fecha_entrega DATE NOT NULL,
    multas_asignada DECIMAL(5,2) NULL,
    multa_pagada DECIMAL(5,2) NULL
)
GO

-- LLAVES PRIMARIAS, FORÁNEAS Y RESTRICCIONES
--------------------------------------------------
ALTER TABLE usuario ADD CONSTRAINT pk_usuario PRIMARY KEY NONCLUSTERED (usuario_no) ON FG_IDX
ALTER TABLE titulo ADD CONSTRAINT pk_titulo PRIMARY KEY NONCLUSTERED (titulo_no) ON FG_IDX
ALTER TABLE adulto ADD CONSTRAINT pk_adulto PRIMARY KEY NONCLUSTERED (usuario_no) ON FG_IDX
ALTER TABLE joven ADD CONSTRAINT pk_joven PRIMARY KEY NONCLUSTERED (usuario_no) ON FG_IDX
ALTER TABLE descripcion_libro ADD CONSTRAINT pk_descripcion_libro PRIMARY KEY NONCLUSTERED (isbn) ON FG_IDX
ALTER TABLE copia ADD CONSTRAINT pk_copia PRIMARY KEY NONCLUSTERED (isbn, copy_no) ON FG_IDX
ALTER TABLE reservaciones ADD CONSTRAINT pk_reservaciones PRIMARY KEY NONCLUSTERED (isbn, usuario_no) ON FG_IDX
ALTER TABLE prestamo ADD CONSTRAINT pk_prestamo PRIMARY KEY NONCLUSTERED (isbn, copy_no, fecha_prestamo) ON FG_IDX

ALTER TABLE historico_prestamo ADD CONSTRAINT pk_historico_prestamo
PRIMARY KEY CLUSTERED (isbn, copy_no, fecha_prestamo)
ON ps_prestamos_por_año(fecha_prestamo)
GO

-- Llaves Foráneas
ALTER TABLE adulto ADD CONSTRAINT fk_adulto_usuario FOREIGN KEY (usuario_no) REFERENCES usuario(usuario_no)
ALTER TABLE joven ADD CONSTRAINT fk_joven_usuario FOREIGN KEY (usuario_no) REFERENCES usuario(usuario_no)
ALTER TABLE joven ADD CONSTRAINT fk_joven_adulto FOREIGN KEY (adult_usuario_no) REFERENCES adulto(usuario_no)
ALTER TABLE descripcion_libro ADD CONSTRAINT fk_descripcion_libro_titulo FOREIGN KEY (titulo_no) REFERENCES titulo(titulo_no)
ALTER TABLE copia ADD CONSTRAINT fk_copia_descripcion_libro FOREIGN KEY (isbn) REFERENCES descripcion_libro(isbn)
ALTER TABLE copia ADD CONSTRAINT fk_copia_titulo FOREIGN KEY (titulo_no) REFERENCES titulo(titulo_no)
ALTER TABLE reservaciones ADD CONSTRAINT fk_reservaciones_descripcion_libro FOREIGN KEY (isbn) REFERENCES descripcion_libro(isbn)
ALTER TABLE reservaciones ADD CONSTRAINT fk_reservaciones_usuario FOREIGN KEY (usuario_no) REFERENCES usuario(usuario_no)
ALTER TABLE prestamo ADD CONSTRAINT fk_prestamo_copia FOREIGN KEY (isbn, copy_no) REFERENCES copia(isbn, copy_no)
ALTER TABLE prestamo ADD CONSTRAINT fk_prestamo_titulo FOREIGN KEY (titulo_no) REFERENCES titulo(titulo_no)
ALTER TABLE prestamo ADD CONSTRAINT fk_prestamo_usuario FOREIGN KEY (usuario_no) REFERENCES usuario(usuario_no)
ALTER TABLE historico_prestamo ADD CONSTRAINT fk_historico_prestamo_copia FOREIGN KEY (isbn, copy_no) REFERENCES copia(isbn, copy_no)
ALTER TABLE historico_prestamo ADD CONSTRAINT fk_historico_prestamo_titulo FOREIGN KEY (titulo_no) REFERENCES titulo(titulo_no)
ALTER TABLE historico_prestamo ADD CONSTRAINT fk_historico_prestamo_usuario FOREIGN KEY (usuario_no) REFERENCES usuario(usuario_no)
GO

-- Restricciones CHECK y UNICAS
ALTER TABLE descripcion_libro ADD CONSTRAINT ck_descripcion_libro_pasta CHECK (pasta IN ('suave', 'dura'))
ALTER TABLE historico_prestamo ADD CONSTRAINT ck_historico_prestamo_multas_asignada CHECK (multas_asignada >= 0)
ALTER TABLE historico_prestamo ADD CONSTRAINT ck_historico_prestamo_multa_pagada CHECK (multa_pagada >= 0)
ALTER TABLE descripcion_libro ADD CONSTRAINT ck_descripcion_libro_prestable CHECK ( prestable IN ('N','Y'))
ALTER TABLE copia ADD CONSTRAINT ck_copia_en_prestamo CHECK ( en_prestamo IN ('N','Y'))
ALTER TABLE adulto ADD CONSTRAINT ck_adulto_telefono CHECK (LEN(telefono)=10)
ALTER TABLE adulto ADD CONSTRAINT ck_adulto_codigopostal CHECK (LEN(codigopostal)=5)
GO

-- ÍNDICES NONCLUSTERED (INDEX COVERING / OPTIMIZACIÓN)
--------------------------------------------------
CREATE NONCLUSTERED INDEX IX_Titulo_Autor ON titulo(autor) INCLUDE (titulo) ON FG_IDX
GO
CREATE NONCLUSTERED INDEX IX_Copia_Disponibilidad ON copia(isbn, en_prestamo) INCLUDE (copy_no) ON FG_IDX
GO
CREATE NONCLUSTERED INDEX IX_Historico_Usuario_Fecha ON historico_prestamo(usuario_no, fecha_prestamo) INCLUDE (isbn, copy_no) ON FG_IDX
GO
CREATE NONCLUSTERED INDEX IX_Adulto_Ciudad_Estado ON adulto(ciudad, estado) INCLUDE (usuario_no, telefono) ON FG_IDX
GO
CREATE NONCLUSTERED INDEX IX_Joven_FechaNacimiento ON joven(fechanacimiento) INCLUDE (usuario_no) ON FG_IDX
GO
CREATE UNIQUE INDEX uq_adulto_telefono_notnull
ON dbo.adulto(telefono)
WHERE telefono IS NOT NULL
ON FG_IDX
GO

-- INSERCIÓN DE DATOS DE EJEMPLO
--------------------------------------------------
BEGIN TRANSACTION

INSERT INTO titulo (titulo_no, titulo, autor) VALUES
(101, 'Cien Años de Soledad', 'Gabriel García Márquez'), (102, 'El Señor de los Anillos', 'J.R.R. Tolkien'),
(103, '1984', 'George Orwell'), (104, 'Don Quijote de la Mancha', 'Miguel de Cervantes'),
(105, 'La Sombra del Viento', 'Carlos Ruiz Zafón'), (106, 'Dune', 'Frank Herbert'),
(107, 'Fahrenheit 451', 'Ray Bradbury'), (108, 'Matar a un Ruiseñor', 'Harper Lee'),
(109, 'El Hobbit', 'J.R.R. Tolkien'), (110, 'Orgullo y Prejuicio', 'Jane Austen'),
(111, 'Crimen y Castigo', 'Fyodor Dostoevsky'), (112, 'La Casa de los Espíritus', 'Isabel Allende'),
(113, 'Un Mundo Feliz', 'Aldous Huxley'), (114, 'Ensayo sobre la Ceguera', 'José Saramago'),
(115, 'Pedro Páramo', 'Juan Rulfo')
GO

INSERT INTO usuario (usuario_no, nombre, apellido, inicial) VALUES
(1, 'Ricardo', 'Montes', 'R'), (2, 'Sofia', 'Hernández', 'S'),
(3, 'Mateo', 'Gómez', 'M'), (4, 'Valentina', 'Díaz', 'V'),
(5, 'Javier', 'Moreno', 'J'), (6, 'Camila', 'Jiménez', 'C'),
(7, 'Daniel', 'Ruiz', 'D'), (8, 'Isabella', 'Álvarez', 'I'),
(9, 'Alejandro', 'Romero', 'A'), (10, 'Mariana', 'Navarro', 'M'),
(11, 'Diego', 'Castro', 'D'), (12, 'Valeria', 'Ortega', 'V'),
(13, 'Sebastián', 'Guerrero', 'S'), (14, 'Gabriela', 'Ramos', 'G'),
(15, 'Andrés', 'Vega', 'A')
GO

INSERT INTO adulto (usuario_no, calle, codigopostal, ciudad, estado, telefono, fecha_exp) VALUES
(1, 'Av. de la Reforma 222', '06600', 'Ciudad de México', 'CDMX', '5512345678', '2026-10-16'),
(2, 'Calle Pino Suárez 10', '44100', 'Guadalajara', 'Jalisco', '3318765432', '2025-11-30'),
(3, 'Av. Constitución 400', '64000', 'Monterrey', 'Nuevo León', '8198765432', '2027-01-01'),
(4, 'Calle 60 491A', '97000', 'Mérida', 'Yucatán', NULL, '2026-05-01'),
(5, 'Blvd. Adolfo López Mateos 1800', '37530', 'León', 'Guanajuato', '4771231234', '2027-03-15'),
(6, 'Av. Insurgentes Sur 3000', '04510', 'Ciudad de México', 'CDMX', '5587654321', '2025-12-20'),
(7, 'Calle Álvaro Obregón 123', '80000', 'Culiacán', 'Sinaloa', '6678889900', '2026-08-08'),
(8, 'Paseo de la Rosaleda 45', '81200', 'Los Mochis', 'Sinaloa', '6681122334', '2026-09-01')
GO

INSERT INTO joven (usuario_no, fechanacimiento, adult_usuario_no) VALUES
(9, '2006-05-21', 1), (10, '2008-11-02', 2), (11, '2005-01-30', 3),
(12, '2007-07-14', 4), (13, '2009-03-19', 5), (14, '2006-09-09', 6),
(15, '2004-12-25', 7);
GO

INSERT INTO descripcion_libro (isbn, idioma, pasta, prestable, titulo_no) VALUES
('9788437600000', 'Español', 'suave', 'Y', 101), ('9780618600000', 'Inglés', 'dura', 'Y', 102),
('9780451500000', 'Inglés', 'suave', 'N', 103), ('9788424100000', 'Español', 'dura', 'Y', 104),
('9788408000000', 'Español', 'dura', 'Y', 105), ('9780441000000', 'Inglés', 'suave', 'Y', 106),
('9781451600000', 'Inglés', 'suave', 'Y', 107), ('9780061100000', 'Inglés', 'suave', 'Y', 108),
('9780618200000', 'Inglés', 'dura', 'Y', 109), ('9780141400000', 'Inglés', 'suave', 'Y', 110),
('9780679700000', 'Inglés', 'suave', 'N', 111), ('9780307300000', 'Español', 'dura', 'Y', 112),
('9780060800000', 'Inglés', 'suave', 'Y', 113), ('9789722100000', 'Portugués', 'dura', 'Y', 114),
('9789685100000', 'Español', 'suave', 'Y', 115)
GO

INSERT INTO copia (copy_no, en_prestamo, isbn, titulo_no) VALUES
(1, 'N', '9788437600000', 101), (2, 'N', '9788437600000', 101),
(1, 'N', '9780618600000', 102), (2, 'N', '9780618600000', 102), (3, 'N', '9780618600000', 102),
(1, 'N', '9780451500000', 103), (1, 'N', '9788424100000', 104), (2, 'N', '9788424100000', 104),
(1, 'N', '9788408000000', 105), (1, 'N', '9780441000000', 106), (2, 'N', '9780441000000', 106),
(1, 'N', '9781451600000', 107), (1, 'N', '9780061100000', 108), (2, 'N', '9780061100000', 108),
(1, 'N', '9780618200000', 109), (1, 'N', '9780141400000', 110), (1, 'N', '9780679700000', 111),
(1, 'N', '9780307300000', 112), (2, 'N', '9780307300000', 112), (1, 'N', '9780060800000', 113),
(1, 'N', '9789722100000', 114), (1, 'N', '9789685100000', 115), (2, 'N', '9789685100000', 115)
GO

INSERT INTO reservaciones (fecha_reserva, isbn, usuario_no) VALUES
('1999-10-14', '9788437600000', 1), ('2001-08-20', '9780618600000', 2), ('2003-05-15', '9788424100000', 3),
('2005-02-01', '9788408000000', 4), ('2007-11-30', '9780441000000', 5), ('2009-09-05', '9781451600000', 6),
('2011-07-18', '9780061100000', 7), ('2013-04-12', '9780618200000', 8), ('2015-01-25', '9780141400000', 9),
('2017-10-02', '9780307300000', 10), ('2019-08-22', '9780060800000', 11), ('2021-06-16', '9789722100000', 12),
('2023-03-09', '9789685100000', 13), ('2024-12-25', '9788437600000', 14), ('2025-09-01', '9780618600000', 15)
GO

INSERT INTO historico_prestamo (fecha_entrega, multas_asignada, multa_pagada, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo, fecha_regreso) VALUES
('2000-03-15', 0.00, 0.00, '9788437600000', 1, 101, 1, '2000-02-15', '2000-03-15'),
('2001-07-22', 15.50, 15.50, '9780618600000', 1, 102, 2, '2001-06-20', '2001-07-20'),
('2002-11-30', 0.00, 0.00, '9788424100000', 1, 104, 3, '2002-10-30', '2002-11-30'),
('2003-01-10', 0.00, 0.00, '9788408000000', 1, 105, 4, '2002-12-10', '2003-01-10'),
('2004-05-05', 0.00, 0.00, '9780441000000', 1, 106, 5, '2004-04-05', '2004-05-05'),
('2005-09-18', 0.00, 0.00, '9781451600000', 1, 107, 6, '2005-08-18', '2005-09-18'),
('2008-04-25', 45.00, 45.00, '9780061100000', 1, 108, 7, '2008-03-20', '2008-04-20'),
('2010-02-14', 0.00, 0.00, '9780618200000', 1, 109, 8, '2010-01-14', '2010-02-14'),
('2012-10-01', 0.00, 0.00, '9780141400000', 1, 110, 9, '2012-09-01', '2012-10-01'),
('2014-06-07', 0.00, 0.00, '9780307300000', 1, 112, 10, '2014-05-07', '2014-06-07'),
('2016-08-11', 10.00, 0.00, '9780060800000', 1, 113, 11, '2016-07-10', '2016-08-10'),
('2018-03-20', 0.00, 0.00, '9789722100000', 1, 114, 12, '2018-02-20', '2018-03-20'),
('2020-12-24', 0.00, 0.00, '9789685100000', 1, 115, 13, '2020-11-24', '2020-12-24'),
('2022-07-07', 25.00, 25.00, '9788437600000', 2, 101, 14, '2022-06-01', '2022-07-01'),
('2023-11-11', 0.00, 0.00, '9780618600000', 2, 102, 15, '2023-10-11', '2023-11-11'),
('2024-01-15', 0.00, 0.00, '9788424100000', 2, 104, 1, '2023-12-15', '2024-01-15'),
('2024-03-20', 12.00, 12.00, '9780441000000', 2, 106, 2, '2024-02-18', '2024-03-18'),
('2024-05-10', 0.00, 0.00, '9780061100000', 2, 108, 3, '2024-04-10', '2024-05-10'),
('2024-08-01', 0.00, 0.00, '9780307300000', 2, 112, 4, '2024-07-01', '2024-08-01'),
('2024-10-05', 5.50, 5.50, '9789685100000', 2, 115, 5, '2024-09-04', '2024-10-04')
GO


INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-11-20', '9788437600000', 1, 101, 1, '2025-11-05'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9788437600000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-11-15', '9780618600000', 1, 102, 3, '2025-10-31'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9780618600000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-12-01', '9788424100000', 1, 104, 5, '2025-11-16'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9788424100000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-11-25', '9780441000000', 1, 106, 7, '2025-11-10'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9780441000000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-11-30', '9780061100000', 1, 108, 9, '2025-11-15'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9780061100000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-12-10', '9780307300000', 1, 112, 11, '2025-11-25'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9780307300000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-12-05', '9789722100000', 1, 114, 13, '2025-11-20'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9789722100000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-11-18', '9789685100000', 1, 115, 15, '2025-11-03'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9789685100000' AND copy_no=1
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-11-22', '9788437600000', 2, 101, 2, '2025-11-07'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9788437600000' AND copy_no=2
INSERT INTO prestamo (fecha_regreso, isbn, copy_no, titulo_no, usuario_no, fecha_prestamo) VALUES ('2025-11-28', '9780618600000', 2, 102, 4, '2025-11-13'); UPDATE copia SET en_prestamo = 'Y' WHERE isbn='9780618600000' AND copy_no=2
GO

COMMIT TRANSACTION
GO

-- PROCEDIMIENTOS ALMACENADOS (SPs)
--------------------------------------------------

CREATE OR ALTER PROCEDURE sp_realizar_prestamo
    @usuario_no INT,
    @isbn VARCHAR(13),
    @fecha_prestamo DATE
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @copy_no INT
    DECLARE @titulo_no INT
    DECLARE @fecha_regreso DATE = DATEADD(DAY, 15, @fecha_prestamo)
    DECLARE @fecha_vigencia DATE
    
    -- Validar Usuario y Vigencia (REGLA DE NEGOCIO)
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE usuario_no = @usuario_no)
    BEGIN
        RAISERROR('El usuario no existe.', 16, 1)
        RETURN
    END

    -- Obtener fecha de expiración del adulto (o aval, si es joven)
    SELECT @fecha_vigencia = a.fecha_exp
    FROM adulto a
    LEFT JOIN joven j ON a.usuario_no = j.adult_usuario_no
    WHERE a.usuario_no = @usuario_no OR j.usuario_no = @usuario_no

    -- Si el usuario o su aval tienen membresía expirada (considerando la fecha de préstamo como "hoy")
    IF (@fecha_vigencia IS NOT NULL AND @fecha_vigencia < @fecha_prestamo)
    BEGIN
        RAISERROR('La membresía del usuario o su aval ha expirado. No se puede realizar el préstamo.', 16, 1)
        RETURN
    END

    -- Encontrar Copia Disponible y Título (Sólo si es prestable)
    SELECT TOP 1 @copy_no = c.copy_no, @titulo_no = c.titulo_no
    FROM copia c
    JOIN descripcion_libro dl ON c.isbn = dl.isbn
    WHERE c.isbn = @isbn AND c.en_prestamo = 'N' AND dl.prestable = 'Y'
    ORDER BY c.copy_no ASC

    IF @copy_no IS NULL
    BEGIN
        RAISERROR('No hay copias disponibles de este libro para préstamo.', 16, 1)
        RETURN
    END

    -- Realizar Transacción
    BEGIN TRANSACTION
    BEGIN TRY
        UPDATE copia
        SET en_prestamo = 'Y'
        WHERE isbn = @isbn AND copy_no = @copy_no

        INSERT INTO prestamo (isbn, copy_no, titulo_no, usuario_no, fecha_prestamo, fecha_regreso)
        VALUES (@isbn, @copy_no, @titulo_no, @usuario_no, @fecha_prestamo, @fecha_regreso)

        COMMIT TRANSACTION
        PRINT 'Préstamo realizado con éxito para la copia: ' + CAST(@copy_no AS VARCHAR)
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        THROW
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_realizar_devolucion
    @isbn VARCHAR(13),
    @copy_no INT,
    @fecha_entrega DATE,
    @multa_diaria DECIMAL(5, 2) = 2.50
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @fecha_prestamo DATE, @fecha_regreso DATE, @usuario_no INT, @titulo_no INT
    DECLARE @multa DECIMAL(5, 2) = 0.00
    
    -- Obtener datos del préstamo activo
    SELECT @fecha_prestamo = fecha_prestamo, @fecha_regreso = fecha_regreso,
           @usuario_no = usuario_no, @titulo_no = titulo_no
    FROM prestamo
    WHERE isbn = @isbn AND copy_no = @copy_no

    IF @fecha_prestamo IS NULL
    BEGIN
        RAISERROR('No se encontró un préstamo activo para esta copia.', 16, 1)
        RETURN
    END

    -- Calcular Multa
    IF @fecha_entrega > @fecha_regreso
    BEGIN
        SET @multa = DATEDIFF(DAY, @fecha_regreso, @fecha_entrega) * @multa_diaria
    END
    
    -- Realizar Transacción
    BEGIN TRANSACTION
    BEGIN TRY
        -- Mover a Histórico_Prestamo
        INSERT INTO historico_prestamo (
            isbn, copy_no, titulo_no, usuario_no,
            fecha_prestamo, fecha_regreso, fecha_entrega,
            multas_asignada, multa_pagada
        ) VALUES (
            @isbn, @copy_no, @titulo_no, @usuario_no,
            @fecha_prestamo, @fecha_regreso, @fecha_entrega,
            @multa, 0.00 
        );

        -- Eliminar de Préstamo Activo
        DELETE FROM prestamo
        WHERE isbn = @isbn AND copy_no = @copy_no AND fecha_prestamo = @fecha_prestamo;

        -- Actualizar Copia
        UPDATE copia
        SET en_prestamo = 'N'
        WHERE isbn = @isbn AND copy_no = @copy_no

        COMMIT TRANSACTION;
        PRINT 'Devolución realizada con éxito. Multa asignada: $' + CAST(@multa AS VARCHAR(10))
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        THROW
    END CATCH
END
GO

-- CONSULTAS DE EJEMPLO (Usan Index Covering para optimizar)
--------------------------------------------------

-- 1. Títulos y autores de J.R.R. Tolkien
SELECT titulo, autor FROM titulo WHERE autor = 'J.R.R. Tolkien'
GO
-- 2. Copias disponibles del ISBN 9780618600000
SELECT copy_no FROM copia WHERE isbn = '9780618600000' AND en_prestamo = 'N'
GO
-- 3. Historial de préstamos del usuario 1 en el año 2000
SELECT isbn, copy_no, fecha_prestamo FROM historico_prestamo WHERE usuario_no = 1 AND YEAR(fecha_prestamo) = 2000
GO
-- 4. Nombre y ubicación de los adultos en Culiacán, Sinaloa
SELECT u.nombre, u.apellido, a.ciudad FROM adulto a JOIN usuario u ON a.usuario_no = u.usuario_no WHERE a.ciudad = 'Culiacán' AND a.estado = 'Sinaloa'
GO
-- 5. Usuarios jóvenes nacidos después de 2007
SELECT usuario_no FROM joven WHERE fechanacimiento > '2007-12-31'
GO
-- 6. ISBNs de libros no prestables (Sala)
SELECT isbn FROM descripcion_libro WHERE prestable = 'N'
GO
-- 7. ISBNs reservados por el usuario 14
SELECT isbn FROM reservaciones WHERE usuario_no = 14
GO
-- 8. Título y autor de un ISBN específico
SELECT t.titulo, t.autor 
FROM descripcion_libro dl JOIN titulo t ON dl.titulo_no = t.titulo_no 
WHERE dl.isbn = '9788437600000'
GO
-- 9. Teléfono del adulto con usuario_no 1
SELECT telefono FROM adulto WHERE usuario_no = 1
GO
-- 10. Adulto que es aval del joven con usuario_no 9
SELECT adult_usuario_no FROM joven WHERE usuario_no = 9
GO