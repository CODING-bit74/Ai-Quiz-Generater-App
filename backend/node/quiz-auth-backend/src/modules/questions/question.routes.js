const express = require('express');
const router = express.Router();
const controller = require('./question.controller');
// const auth = require('../../middlewares/auth.middleware');
const role = require('../../middlewares/role.middleware');

router.post('/', role.isAdmin, controller.createQuestion);

module.exports = router;