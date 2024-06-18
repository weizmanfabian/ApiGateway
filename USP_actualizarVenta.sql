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
