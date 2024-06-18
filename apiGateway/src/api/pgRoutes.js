const express = require("express");
const { createDefault, deleteDefault, findAllDefault, findByKeyDefault, updateDefault } = require("../controllers/pgController");
const router = express.Router();

router.get("/:table", findAllDefault);
router.get("/:table/:key/:value", findByKeyDefault);
router.post("/:table/", createDefault);
router.put("/:table/:key/:value", updateDefault);
router.delete("/:table/:key/:value", deleteDefault);

module.exports = router;