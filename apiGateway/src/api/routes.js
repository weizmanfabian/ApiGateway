const express = require("express");
const { findAllFacturas,
    findFactura,
    insertarVentaF,
    deleteVenta,
    actualizarVentaF, findByKeyDefault } = require("../controllers/controller.js");
const router = express.Router();

router.get("/", findAllFacturas);
router.get("/:facturaId", findFactura);
router.get("/:table/:key/:value", findByKeyDefault);
router.post("/", insertarVentaF);
router.put("/", actualizarVentaF);
router.delete("/:facturaId", deleteVenta);

module.exports = router;

/* Agregar al USP el estado al registrar la factura */