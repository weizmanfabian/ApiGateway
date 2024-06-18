const dotenv = require('dotenv');
dotenv.config();

module.exports = {
    app: {
        port: Number.parseInt(process.env.APP_PORT)
    },
    sqlServer: {
        server: process.env.SQL_SERVER_SERVER,
        database: process.env.SQL_SERVER_DATABASE,
        user: process.env.SQL_SERVER_USER,
        password: process.env.SQL_SERVER_PASSWORD,
        port: Number.parseInt(process.env.SQL_SERVER_PORT)
    },
    postgres: {
        host: process.env.PG_HOST,
        user: process.env.PG_USER,
        password: process.env.PG_PASSWORD,
        database: process.env.PG_DATABASE,
        port: process.env.PG_PORT,
    }
};
