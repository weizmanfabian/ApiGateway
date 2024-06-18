const sql = require('mssql');
const config = require('../config');

// Configuración de la base de datos
const configDB1 = {
    server: config.sqlServer.server, //'localhost'
    database: config.sqlServer.database,
    options: {
        trustedConnection: true, // Usar autenticación de Windows
        enableArithAbort: true,
    },
    driver: 'msnodesqlv8' // Necesario para la autenticación de Windows
};

const configDB2 = {
    server: config.sqlServer.server,
    database: config.sqlServer.database,
    driver: 'msnodesqlv8',
    options: {
        trustedConnection: true,
        //enableArithAbort: true,
        instanceName: 'MSSQLSERVER02', // Especificar el nombre de la instancia
    }
};

// Configuración de la base de datos
const configDB3 = {
    server: config.sqlServer.server, // 'WEIZMAN'
    database: config.sqlServer.database, // 'ejemplo'
    options: {
        trustedConnection: true, // Usar autenticación de Windows
        instanceName: config.sqlServer.instanceName, // 'MSSQLSERVER02'
    },
    driver: 'msnodesqlv8' // Necesario para la autenticación de Windows
};

const { user, password, server, database, port } = config.sqlServer;

const configDB = {
    user: user,
    password: password,
    server: server,
    database: database,
    port: port,
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
}

sql.connect(configDB, err => {
    if (err) {
        console.error('Connection SqlServer error:', err);
        return;
    }
    console.log('Connected successfully to SqlServer');
    // sql.query('SELECT * from cliente', (err, result) => {
    //     if (err) {
    //         console.error('Query error:', err);
    //     } else {
    //         console.log('Query result:', result.rowsAffected);
    //     }
    //     sql.close();
    // });
});

const insertarVenta = async (clienteId, detallesFactura) => {
    try {
        pool = await sql.connect(configDB);

        console.log(`insertarVenta.clienteId: ${clienteId}`)

        // Crear un nuevo objeto de tabla
        const table = new sql.Table('detalleFacturaIn');
        table.columns.add('productoId', sql.Int);
        table.columns.add('cantidad', sql.Int);

        // Llenar la tabla con los detalles de la factura
        detallesFactura.forEach(detalle => {
            table.rows.add(detalle.productoId, detalle.cantidad);
        });

        // Crear una nueva instancia de Request
        const request = new sql.Request(pool);
        request.input('clienteIdIn', sql.Int, Number.parseInt(clienteId));
        request.input('detalleFacturaIn', table);

        const result = await request.execute('USP_insertarVenta');

        console.log('Venta insertada con éxito:', result);
    } catch (err) {
        console.error('Error al insertar la venta:', err);
        throw {
            msg: `Ocurrió un error al intentar registrar la venta => ${err.message}`,
            status: 401
        };
    } finally {
        await sql.close();
    }
};

const deleteByFacturaId = async (facturaId) => {
    try {
        const pool = await sql.connect(configDB);
        const result = await new sql.Request(pool)
            .input('facturaId', sql.Int, facturaId)
            .execute('USP_eliminarVenta');

        console.log('Venta eliminada con éxito:', result);
    } catch (err) {
        console.error('Error al eliminar la venta:', err);
        throw {
            msg: `Ocurrió un error al intentar eliminar la venta => ${err.message}`,
            status: 401
        };
    } finally {
        await sql.close();
    }
};

const findAllFacturas = async () => {
    try {
        await sql.connect(configDB);
        const result = await sql.query("SELECT * FROM factura WHERE facEstado = 'PAGADA'");
        return result.recordset;
    } catch (err) {
        console.error('Error al buscar todas las facturas:', err);
        throw err;
    } finally {
        await sql.close();
    }
};

const findByFacturaId = async (facturaId) => {
    try {
        console.log(`findByFacturaId.facturaId: ${facturaId}`)
        pool = await sql.connect(configDB);
        const request = await new sql.Request(pool);
        const result = await request
            .input('facturaId', sql.Int, facturaId)
            .query('SELECT * FROM FACTURA WHERE facId = @facturaId');

        return result.rowsAffected == 1 ? result.recordset[0] : result.recordset;
    } catch (err) {
        console.error('Error al buscar la factura por clave:', err);
        throw {
            msg: `Ocurrió un error al intentar registrar la venta => ${err.message}`,
            status: 401
        };
    } finally {
        await sql.close();
    }
};

const findByKey = async (table, key, value) => {
    console.log(`findByKey=> table: ${table}, key: ${key}, value: ${value}`);
    try {
        pool = await sql.connect(configDB);
        const request = new sql.Request(pool);

        // Determina el tipo de dato del valor
        let sqlType;
        if (Number.isInteger(value)) {
            sqlType = sql.Int;
        } else {
            sqlType = sql.VarChar;
        }

        const result = await request
            .input(key, sqlType, value)
            .query(`SELECT * FROM ${table} WHERE ${key} = @${key}`);

        console.log(`findByKey=> table: ${table}, key: ${key}, value: ${value}, results: ${result.rowsAffected}`);
        return result.rowsAffected == 1 ? result.recordset[0] : result.recordset;
    } catch (err) {
        console.error('findByKey err:', err);
        throw {
            msg: `Ocurrió un error al intentar buscar por ${key}: ${value} => ${err.message}`,
            status: 401
        };
    } finally {
        await sql.close();
    }
};

const actualizarVenta = async (facturaId, clienteId, detallesFactura) => {
    try {
        const pool = await sql.connect(configDB);
        const request = new sql.Request(pool);

        console.log(`actualizarVenta.facturaId: ${facturaId} actualizarVenta.clienteId: ${clienteId}`)

        const table = new sql.Table();
        table.columns.add('productoId', sql.Int);
        table.columns.add('cantidad', sql.Int);

        detallesFactura.forEach(detalle => {
            table.rows.add(detalle.productoId, detalle.cantidad);
        });

        const result = await request
            .input('facturaId', sql.Int, facturaId)
            .input('clienteIdIn', sql.Int, clienteId)
            .input('detalleFacturaIn', table)
            .execute('USP_actualizarVenta');

        console.log('Venta actualizada con éxito:', result);
    } catch (err) {
        console.error('Error al actualizar la venta:', err);
        throw {
            msg: `Ocurrió un error al intentar actualizar la venta => ${err.message}`,
            status: 401
        };
    } finally {
        await sql.close();
    }
};



module.exports = {
    findAllFacturas,
    findByFacturaId,
    insertarVenta,
    deleteByFacturaId,
    actualizarVenta,
    findByKey
};
