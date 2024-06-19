const { Client } = require('pg');
const config = require('../config');

let conexion = null;

const getConnection = async () => {
    if (!conexion) {
        conexion = new Client({
            host: config.postgres.host,
            user: config.postgres.user,
            password: config.postgres.password,
            database: config.postgres.database,
            port: config.postgres.port,
        });

        try {
            await conexion.connect();
            console.log('Connected successfully to PostgreSql');
        } catch (err) {
            console.error('Connection PostgreSql error:', err);
            throw err;
        }
    }
    return conexion;
};

getConnection();

const create1 = async (table, data) => {
    console.log(`create=> table: ${table} data: ${JSON.stringify(data)}`);
    // Construir la consulta de inserción dinámicamente
    const columns = Object.keys(data).join(', ');
    const values = Object.values(data);
    const placeholders = values.map((_, index) => `$${index + 1}`).join(', ');
    const client = await getConnection();
    try {
        const query = `INSERT INTO ${table} (${columns}) VALUES (${placeholders})`;
        const res = await client.query(query, values);
        console.log(res)
        return { id: res.rows[0].id, msg: "Registro exitoso" };
    } catch (err) {
        throw err;
    }
};

const create = async (table, data) => {
    console.log(`create=> table: ${table} data: ${JSON.stringify(data)}`);
    
    // Construir la consulta de inserción dinámicamente
    const columns = Object.keys(data).join(', ');
    const values = Object.values(data);
    const placeholders = values.map((_, index) => `$${index + 1}`).join(', ');
    
    const client = await getConnection();
    try {
        const query = `INSERT INTO ${table} (${columns}) VALUES (${placeholders}) RETURNING proId`;
        const res = await client.query(query, values);
        // Devolver el ID del registro insertado
        console.log(`res: ${JSON.stringify(res.rows[0].proid)}`)
        return {id: res.rows[0].proid, msg: "Registro exitoso"}
    } catch (err) {
        throw err;
    } 
};

const deleteByKey = async (table, key, value) => {
    console.log(`deleteByKey=> table: ${table}, key: ${key}, value: ${value}`);
    const client = await getConnection();
    try {
        const temp = await findByKey(table, key, value);
        if (temp.length !== 0) {
            await client.query(`DELETE FROM ${table} WHERE ${key} = $1`, [value]);
            return "Registro eliminado";
        } else {
            throw { msg: 'El registro que intenta eliminar no existe', status: 404 };
        }
    } catch (err) {
        throw err;
    }
};

const findAll = async (table) => {
    console.log(`findAll=> table: ${table}`);
    const client = await getConnection();
    try {
        const res = await client.query(`SELECT * FROM ${table}`);
        return res.rows;
    } catch (err) {
        throw err;
    }
};

const findByKey = async (table, key, value) => {
    console.log(`findByKey=> table: ${table}, key: ${key}, value: ${value}`);
    const client = await getConnection();
    try {
        const res = await client.query(`SELECT * FROM ${table} WHERE ${key} = $1`, [value]);
        return res.rows;
    } catch (err) {
        throw err;
    }
};

const update = async (table, key, value, data) => {
    console.log(`update=> table: ${table}, key: ${key}, value: ${value}, data: ${JSON.stringify(data)}`);
    const client = await getConnection();
    try {
        const temp = await findByKey(table, key, value);
        if (temp.length !== 0) {
            // Construir la lista de asignaciones para la actualización
            const assignments = Object.keys(data).map((column, index) => `${column} = $${index + 1}`).join(', ');
            const values = Object.values(data);
            // Agregar el valor de la clave para la condición WHERE al final de la matriz de valores
            values.push(value);
            const query = `UPDATE ${table} SET ${assignments} WHERE ${key} = $${values.length}`;
            await client.query(query, values);
            // Después de la actualización, obtener y devolver el registro actualizado
            return (await findByKey(table, key, value))[0];
        } else {
            throw { msg: 'El registro que intenta actualizar no existe', status: 404 };
        }
    } catch (err) {
        throw err;
    }
};


module.exports = {
    findAll,
    findByKey,
    create,
    deleteByKey,
    update
};
