CREATE TABLE cliente (
    cliId INT IDENTITY(1,1) PRIMARY KEY,
    cliNombre VARCHAR(255) NOT NULL,
    cliEmail VARCHAR(255)
);

INSERT INTO cliente (cliNombre, cliEmail) VALUES
('John Doe', 'john.doe@example.com'),
('Jane Smith', 'jane.smith@example.com'),
('Bob Johnson', 'bob.johnson@example.com'),
('Alice Williams', 'alice.williams@example.com'),
('Michael Brown', 'michael.brown@example.com'),
('Emily Davis', 'emily.davis@example.com'),
('David Wilson', 'david.wilson@example.com'),
('Sophia Martinez', 'sophia.martinez@example.com'),
('James Anderson', 'james.anderson@example.com'),
('Isabella Thomas', 'isabella.thomas@example.com');


CREATE TABLE producto (
    proId INT IDENTITY(1,1) PRIMARY KEY,
    proNombre VARCHAR(255) NOT NULL,
    proPrecio DECIMAL(18, 2) NOT NULL,  
    proStock INT NOT NULL  
);

INSERT INTO producto (proNombre, proPrecio, proStock) VALUES
('Producto A', 10.50, 100),
('Producto B', 20.75, 200),
('Producto C', 15.00, 150),
('Producto D', 30.25, 120),
('Producto E', 25.10, 130),
('Producto F', 40.50, 110),
('Producto G', 35.75, 140),
('Producto H', 50.00, 90),
('Producto I', 45.25, 80),
('Producto J', 60.10, 70);


CREATE TABLE factura (
    facId INT IDENTITY(1,1) PRIMARY KEY,
    facClienteId INT NOT NULL,
    facFecha DATETIME NOT NULL,
    facEstado VARCHAR(30) NOT NULL,
    FOREIGN KEY (facClienteId) REFERENCES cliente(cliId),
    CHECK (facEstado IN (
        'EMITIDA',
        'ENVIADA',
        'RECIBIDA',
        'PENDIENTE_DE_PAGO',
        'PAGADA_PARCIALMENTE',
        'PAGADA',
        'VENCIDA',
        'CANCELADA',
        'EN_DISPUTA',
        'DEVUELTA',
        'ARCHIVADA'
    ))
);



CREATE TABLE detalleFactura (
    dtfId INT IDENTITY(1,1) PRIMARY KEY,
    dtfFacturaId INT NOT NULL,
    dtfProductoId INT NOT NULL,
    dtfCantidad INT NOT NULL,
    dtfTotal DECIMAL(18, 2) NOT NULL,  
    FOREIGN KEY (dtfFacturaId) REFERENCES factura(facId),
    FOREIGN KEY (dtfProductoId) REFERENCES producto(proId)
);

----------------------------------------Espacio para los SP -------------------------------------------------

CREATE TYPE DetalleFacturaIn AS TABLE
(
    productoId INT,
    cantidad INT
);



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_insertarVenta]
    @clienteIdIn INT,
    @detalleFacturaIn DetalleFacturaIn READONLY
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificamos que el id del cliente no esté vacío
        IF @clienteIdIn IS NULL
        BEGIN
            RAISERROR('El id del cliente es requerido', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificamos que el cliente exista
        IF NOT EXISTS (SELECT 1 FROM cliente WHERE cliId = @clienteIdIn)
        BEGIN
            RAISERROR('El cliente no existe', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insertamos la factura
        DECLARE @FacturaId INT;
        INSERT INTO factura (facClienteId, facFecha, facEstado)
        VALUES (@clienteIdIn, GETDATE(), 'PAGADA');
        SET @FacturaId = SCOPE_IDENTITY();

        -- Insertamos detalles de la factura
        DECLARE @ProductoId INT, @Cantidad INT;

        DECLARE DetalleCursor CURSOR FOR 
        SELECT productoId, cantidad
        FROM @detalleFacturaIn;

        OPEN DetalleCursor;
        FETCH NEXT FROM DetalleCursor INTO @ProductoId, @Cantidad;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Verificamos que el ProductoId y Cantidad no estén vacíos
            IF @ProductoId IS NULL OR @Cantidad IS NULL OR @Cantidad <= 0
            BEGIN
                RAISERROR('ProductoId y Cantidad son requeridos y Cantidad debe ser mayor a 0', 16, 1);
                ROLLBACK TRANSACTION;
                CLOSE DetalleCursor;
                DEALLOCATE DetalleCursor;
                RETURN;
            END

            -- Verificamos que el producto exista
            IF NOT EXISTS (SELECT 1 FROM producto WHERE proId = @ProductoId)
            BEGIN
                RAISERROR('El producto no existe', 16, 1);
                ROLLBACK TRANSACTION;
                CLOSE DetalleCursor;
                DEALLOCATE DetalleCursor;
                RETURN;
            END

            DECLARE @Precio DECIMAL(18, 2);
            SELECT @Precio = proPrecio FROM producto WHERE proId = @ProductoId;

            -- Insertamos DetalleFactura
            INSERT INTO detalleFactura (dtfFacturaId, dtfProductoId, dtfCantidad, dtfTotal)
            VALUES (@FacturaId, @ProductoId, @Cantidad, @Cantidad * @Precio);

            -- Actualizamos el stock
            UPDATE producto SET proStock = ((SELECT proStock FROM producto WHERE proId = @ProductoId) - @Cantidad) WHERE proId = @ProductoId;
            --update producto set proPrecio = 200000 where proId = 2

            FETCH NEXT FROM DetalleCursor INTO @ProductoId, @Cantidad;
        END

        CLOSE DetalleCursor;
        DEALLOCATE DetalleCursor;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO







SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_actualizarVenta]
    @facturaId INT,
    @clienteIdIn INT,
    @detalleFacturaIn DetalleFacturaIn READONLY
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificamos que el id de la factura y el id del cliente no estén vacíos
        IF @facturaId IS NULL OR @clienteIdIn IS NULL
        BEGIN
            RAISERROR('El id de la factura y el id del cliente son requeridos', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificamos que la factura exista
        IF NOT EXISTS (SELECT 1 FROM factura WHERE facId = @facturaId)
        BEGIN
            RAISERROR('La factura no existe', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificamos que el cliente exista
        IF NOT EXISTS (SELECT 1 FROM cliente WHERE cliId = @clienteIdIn)
        BEGIN
            RAISERROR('El cliente no existe', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Actualizamos la factura
        UPDATE factura
        SET facClienteId = @clienteIdIn
        WHERE facId = @facturaId;

        -- Manejamos los detalles de factura existentes
        DECLARE @ProductoId INT, @Cantidad INT, @OldCantidad INT;

        -- Cursor para iterar sobre los detalles actuales de la factura y restaurar el stock
        DECLARE OldDetalleCursor CURSOR FOR 
        SELECT dtfProductoId, dtfCantidad
        FROM detalleFactura
        WHERE dtfFacturaId = @facturaId;

        OPEN OldDetalleCursor;
        FETCH NEXT FROM OldDetalleCursor INTO @ProductoId, @OldCantidad;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Restauramos el stock de productos
            UPDATE producto 
            SET proStock = proStock + @OldCantidad
            WHERE proId = @ProductoId;

            FETCH NEXT FROM OldDetalleCursor INTO @ProductoId, @OldCantidad;
        END

        CLOSE OldDetalleCursor;
        DEALLOCATE OldDetalleCursor;

        -- Eliminamos los detalles de factura existentes
        DELETE FROM detalleFactura
        WHERE dtfFacturaId = @facturaId;

        -- Insertamos los nuevos detalles de factura
        DECLARE DetalleCursor CURSOR FOR 
        SELECT productoId, cantidad
        FROM @detalleFacturaIn;

        OPEN DetalleCursor;
        FETCH NEXT FROM DetalleCursor INTO @ProductoId, @Cantidad;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Verificamos que el ProductoId y Cantidad no estén vacíos
            IF @ProductoId IS NULL OR @Cantidad IS NULL OR @Cantidad <= 0
            BEGIN
                RAISERROR('ProductoId y Cantidad son requeridos y Cantidad debe ser mayor a 0', 16, 1);
                ROLLBACK TRANSACTION;
                CLOSE DetalleCursor;
                DEALLOCATE DetalleCursor;
                RETURN;
            END

            -- Verificamos que el producto exista
            IF NOT EXISTS (SELECT 1 FROM producto WHERE proId = @ProductoId)
            BEGIN
                RAISERROR('El producto no existe', 16, 1);
                ROLLBACK TRANSACTION;
                CLOSE DetalleCursor;
                DEALLOCATE DetalleCursor;
                RETURN;
            END

            DECLARE @Precio DECIMAL(18, 2);
            SELECT @Precio = proPrecio FROM producto WHERE proId = @ProductoId;

            -- Insertamos DetalleFactura
            INSERT INTO detalleFactura (dtfFacturaId, dtfProductoId, dtfCantidad, dtfTotal)
            VALUES (@facturaId, @ProductoId, @Cantidad, @Cantidad * @Precio);

            -- Actualizamos el stock
            UPDATE producto SET proStock = ((SELECT proStock FROM producto WHERE proId = @ProductoId) - @Cantidad) WHERE proId = @ProductoId;

            FETCH NEXT FROM DetalleCursor INTO @ProductoId, @Cantidad;
        END

        CLOSE DetalleCursor;
        DEALLOCATE DetalleCursor;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO








SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER   PROCEDURE [dbo].[USP_eliminarVenta]
    @facturaId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificamos que el id de la factura y el id del cliente no estén vacíos
        IF @facturaId IS NULL 
        BEGIN
            RAISERROR('El id de la factura es requerido', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificamos que la factura exista
        IF NOT EXISTS (SELECT 1 FROM factura WHERE facId = @facturaId)
        BEGIN
            RAISERROR('La factura no existe', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Actualizamos la factura
        UPDATE factura
        SET facEstado = 'CANCELADA'
        WHERE facId = @facturaId;

        -- Manejamos los detalles de factura existentes
        DECLARE @ProductoId INT, @Cantidad INT, @OldCantidad INT;

        -- Cursor para iterar sobre los detalles actuales de la factura y restaurar el stock
        DECLARE OldDetalleCursor CURSOR FOR 
        SELECT dtfProductoId, dtfCantidad
        FROM detalleFactura
        WHERE dtfFacturaId = @facturaId;

        OPEN OldDetalleCursor;
        FETCH NEXT FROM OldDetalleCursor INTO @ProductoId, @OldCantidad;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Restauramos el stock de productos
            UPDATE producto 
            SET proStock = proStock + @OldCantidad
            WHERE proId = @ProductoId;

            FETCH NEXT FROM OldDetalleCursor INTO @ProductoId, @OldCantidad;
        END

        CLOSE OldDetalleCursor;
        DEALLOCATE OldDetalleCursor;


        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
