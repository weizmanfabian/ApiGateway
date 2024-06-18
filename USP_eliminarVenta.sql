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
