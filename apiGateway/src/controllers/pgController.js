const { create, deleteByKey, findAll, findByKey, update } = require('../DB/Postgres');
const { error, success } = require('../red/response.js');

// Funciones para operaciones CRUD por defecto
const createDefault = (req, res) => {
    create(req.params.table, req.body)
        .then((rows) => success(req, res, rows))
        .catch((err) => error(req, res, `${err}`, 500));
};

const deleteDefault = (req, res) => {
    deleteByKey(req.params.table, req.params.key, req.params.value)
        .then((rows) => success(req, res, rows))
        .catch(({ msg, status }) => error(req, res, msg, status));
};

const findAllDefault = (req, res) => {
    findAll(req.params.table)
        .then((rows) => success(req, res, rows))
        .catch((err) => error(req, res, `${err}`, 500));
};

const findByKeyDefault = (req, res) => {
    findByKey(req.params.table, req.params.key, req.params.value)
        .then((rows) => success(req, res, rows))
        .catch((err) => error(req, res, `${err}`, 500));
};

const updateDefault = (req, res) => {
    update(req.params.table, req.params.key, req.params.value, req.body)
        .then((rows) => success(req, res, rows))
        .catch(({ msg, status }) => error(req, res, msg, status));
};

module.exports = {
    createDefault,
    deleteDefault,
    findAllDefault,
    findByKeyDefault,
    updateDefault
};
