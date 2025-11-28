/*
================================================================
SCRIPT DE CREACIÓN DE BASE DE DATOS - BIBLIOTECA
================================================================

*/

/*
================================================================
1. CREACIÓN DE LA BASE DE DATOS Y FILEGROUPS
Basado en la Sección 2: Particionamiento y Filegroups [cite: 17]
================================================================
*/

CREATE DATABASE BibliotecaDB
ON PRIMARY
( 
    NAME = 'BibliotecaDB_Primary', 
    FILENAME = 'C:\SQLData\BibliotecaDB_Primary.mdf'
),
FILEGROUP FG_DIM -- Para tablas de dimensión (Libros, Usuarios) 
( 
    NAME = 'BibliotecaDB_Dim', 
    FILENAME = 'C:\SQLData\BibliotecaDB_Dim.ndf'
),
FILEGROUP FG_PRESTAMOS_2025 -- Para partición de préstamos del año actual 
( 
    NAME = 'BibliotecaDB_Prestamos_2025', 
    FILENAME = 'C:\SQLData\BibliotecaDB_Prestamos_2025.ndf'
),
FILEGROUP FG_PRESTAMOS_OLD -- Para particiones antiguas 
( 
    NAME = 'BibliotecaDB_Prestamos_Old', 
    FILENAME = 'C:\SQLData\BibliotecaDB_Prestamos_Old.ndf'
);
GO

-- Cambiar al contexto de la nueva base de datos
USE BibliotecaDB
GO

/*
================================================================
2. CREACIÓN DE FUNCIÓN Y ESQUEMA DE PARTICIÓN
================================================================
*/

-- Función de Partición (ejemplo: partición anual)
CREATE PARTITION FUNCTION PF_Prestamos_PorAnio (DATE)
AS RANGE RIGHT FOR VALUES ('2025-01-01'); -- Límite para separar 2025 de los datos antiguos
GO

-- Esquema de Partición que mapea la función a los Filegroups
CREATE PARTITION SCHEME PS_Prestamos_PorAnio
AS PARTITION PF_Prestamos_PorAnio
TO (FG_PRESTAMOS_OLD, FG_PRESTAMOS_2025) -- 'OLD' a la izquierda, '2025' a la derecha del límite 
GO

/*
================================================================
3. CREACIÓN DE TABLAS
================================================================
*/

-- Tabla Usuarios
CREATE TABLE Usuarios
(
    ControlNum CHAR(8) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    
    -- Columnas inferidas de la Sección 5 (Índices) 
    Direccion NVARCHAR(200) NULL,
    Telefono VARCHAR(20) NULL,
    
    -- Restricción Clustered PK [cite: 23, 26]
    CONSTRAINT PK_Usuarios PRIMARY KEY CLUSTERED (ControlNum ASC)
)
ON FG_DIM; -- Ubicada en el Filegroup de Dimensiones 
GO

CREATE TABLE Libros
(
    ISBN VARCHAR(13) NOT NULL,
    Titulo NVARCHAR(200) NOT NULL,
    Autor NVARCHAR(150) NULL,
    AnioPublicacion SMALLINT NULL,
    CONSTRAINT PK_Libros PRIMARY KEY CLUSTERED (ISBN ASC)
)
ON FG_DIM -- Ubicada en el Filegroup de Dimensiones 
GO

-- Tabla Prestamos
CREATE TABLE dbo.Prestamos
(
    PrestamoID UNIQUEIDENTIFIER NOT NULL,
    ControlNum CHAR(8) NOT NULL,
    ISBN VARCHAR(13) NOT NULL,
    FechaPrestamo DATE NOT NULL,
    FechaDevolucion DATE NULL,

    -- Restricción Non-Clustered PK
    CONSTRAINT PK_Prestamos PRIMARY KEY NONCLUSTERED (PrestamoID ASC),
    
    -- Llaves Foráneas
    CONSTRAINT FK_Prestamos_Usuarios FOREIGN KEY (ControlNum) REFERENCES dbo.Usuarios(ControlNum),
    CONSTRAINT FK_Prestamos_Libros FOREIGN KEY (ISBN) REFERENCES dbo.Libros(ISBN)
)
ON PS_Prestamos_PorAnio (FechaPrestamo) -- Particionada por FechaPrestamo
GO

-- Creación del Índice Clustered para Prestamos (Separado por particionamiento)
CREATE CLUSTERED INDEX CX_Prestamos_Fecha
ON Prestamos (FechaPrestamo, PrestamoID)
ON PS_Prestamos_PorAnio (FechaPrestamo)
GO

/*
================================================================
4. CREACIÓN DE ÍNDICES NON-CLUSTERED
================================================================
*/

-- 1. Para encontrar préstamos activos de un usuario 
CREATE NONCLUSTERED INDEX NCI_Prest_Activos
ON Prestamos (ControlNum)
INCLUDE (ISBN, FechaPrestamo)
WHERE (FechaDevolucion IS NULL)
GO

-- 2. Buscar un libro por título 
CREATE NONCLUSTERED INDEX NCI_Libros_Titulos
ON dbo.Libros (Titulo)
INCLUDE (ISBN)
GO

-- 3. Listar préstamos con fechas vencidas (clave en FechaDevolucion) 
CREATE NONCLUSTERED INDEX NCI_Prest_Vencidos
ON Prestamos (FechaDevolucion)
INCLUDE (ISBN)
GO

-- 4. Historial de préstamos por libro (clave en ControlNum, ISBN) 
CREATE NONCLUSTERED INDEX NCI_Prest_Libro
ON Prestamos (ControlNum, ISBN)
INCLUDE (FechaPrestamo)
GO

-- 5. Listar libros de un autor específico 
CREATE NONCLUSTERED INDEX NCI_Libros_Autor
ON Libros (Autor)
INCLUDE (ISBN, Titulo)
GO

-- 6. Buscar usuario por nombre 
CREATE NONCLUSTERED INDEX NCI_Usuarios_Nombre
ON Usuarios (Nombre)
INCLUDE (ControlNum)
GO

-- 7. Conteo de préstamos por fecha 
CREATE NONCLUSTERED INDEX NCI_Prest_Estadistico
ON Prestamos (FechaPrestamo)
INCLUDE (ISBN)
GO

-- 8. Encontrar usuarios por ubicación 
CREATE NONCLUSTERED INDEX NCI_Usuarios_Direccion
ON Usuarios (Direccion)
INCLUDE (ControlNum, Telefono)
GO

-- 9. Listar libros por año 
CREATE NONCLUSTERED INDEX NCI_Libros_Anio
ON Libros (AnioPublicacion)
INCLUDE (ISBN, Titulo)
GO

-- 10. Devoluciones recientes 
CREATE NONCLUSTERED INDEX NCI_Prest_Dev
ON Prestamos (FechaDevolucion)
INCLUDE (PrestamoID, ISBN)
GO

/*
================================================================
5. CREACIÓN DE PROCEDIMIENTOS ALMACENADOS
================================================================
*/

-- Procedimiento para Realizar Préstamo
CREATE PROCEDURE [SP_RealizarPrestamo]
    @ControlNum CHAR(8), 
    @ISBN VARCHAR(13)
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
    
    BEGIN TRANSACTION
    
    DECLARE @MaxLibros INT = 5
    DECLARE @LibrosActivos INT
    DECLARE @NuevoPrestamoID UNIQUEIDENTIFIER = NEWID()

    -- 1. Validar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE ControlNum = @ControlNum)
    BEGIN
        RAISERROR('Error: El Número de Control de usuario no existe.', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END

    -- 2. Contar libros activos del usuario
    SELECT @LibrosActivos = COUNT(1) 
    FROM Prestamos 
    WHERE ControlNum = @ControlNum AND FechaDevolucion IS NULL

    -- 3. Validar límite de préstamos
    IF @LibrosActivos >= @MaxLibros
    BEGIN
        RAISERROR('Error: Límite de préstamos excedido.', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END

    -- 4. Insertar el nuevo préstamo
    INSERT INTO Prestamos (PrestamoID, ControlNum, ISBN, FechaPrestamo, FechaDevolucion)
    VALUES (@NuevoPrestamoID, @ControlNum, @ISBN, GETDATE(), NULL)
    
    COMMIT TRANSACTION
END
GO

-- Procedimiento para Realizar Devolución
CREATE PROCEDURE [SP_RealizarDevolucion]
    @ControlNum CHAR(8),
    @ISBN VARCHAR(13)
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

    BEGIN TRANSACTION

    DECLARE @PrestamoIDToUpdate UNIQUEIDENTIFIER

    -- 1. Buscar el préstamo activo más antiguo para ese usuario y libro
    SELECT TOP 1 @PrestamoIDToUpdate = PrestamoID
    FROM dbo.Prestamos
    WHERE ControlNum = @ControlNum 
      AND ISBN = @ISBN 
      AND FechaDevolucion IS NULL
    ORDER BY FechaPrestamo ASC

    -- 2. Validar si se encontró el préstamo
    IF @PrestamoIDToUpdate IS NULL
    BEGIN
        RAISERROR('Error: No se encontró un préstamo activo para ese usuario y libro.', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END

    -- 3. Actualizar el préstamo marcando la fecha de devolución
    UPDATE Prestamos 
    SET FechaDevolucion = GETDATE()
    WHERE PrestamoID = @PrestamoIDToUpdate
    
    COMMIT TRANSACTION
END
GO