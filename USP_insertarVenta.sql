SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
CREATE TYPE DetalleFacturaIn AS TABLE
(
    productoId INT,
    cantidad INT
);
GO
*/

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
