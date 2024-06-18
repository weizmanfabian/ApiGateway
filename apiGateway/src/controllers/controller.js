const sqlServer = require('../DB/SqlServer.js');
const { error, success } = require('../red/response.js');

const insertarVentaF = (req, res) => {
    sqlServer.insertarVenta(req.query.clienteId, req.body)
        .then((rows) => success(req, res, rows))
        .catch(({ msg, status }) => error(req, res, msg, status));
};

const deleteVenta = (req, res) => {
    sqlServer.deleteByFacturaId(req.params.facturaId)
        .then((rows) => success(req, res, rows))
        .catch(({ msg, status }) => error(req, res, msg, status));
};

const findAllFacturas = (req, res) => {
    sqlServer.findAllFacturas()
        .then((rows) => success(req, res, rows))
        .catch((err) => error(req, res, `${err}`, 500));
};

const findFactura = (req, res) => {
    sqlServer.findByFacturaId(req.params.facturaId)
        .then((rows) => success(req, res, rows))
        .catch(({ msg, status }) => error(req, res, msg, status));
};

const actualizarVentaF = (req, res) => {
    sqlServer.actualizarVenta(req.query.facturaId, req.query.clienteId, req.body)
        .then((rows) => success(req, res, rows))
        .catch(({ msg, status }) => error(req, res, msg, status));
};

const findByKeyDefault = (req, res) => {
    sqlServer.findByKey(req.params.table, req.params.key, req.params.value)
        .then((rows) => success(req, res, rows))
        .catch((err) => error(req, res, `${err}`, 500));
};

module.exports = {
    findAllFacturas,
    findFactura,
    insertarVentaF,
    deleteVenta,
    actualizarVentaF,
    findByKeyDefault
};