const express = require('express');
const router = express.Router();
const controller = require('./progress.controller');
const auth = require('../../middlewares/auth.middleware');

router.get('/', auth.requireAuth, controller.getProgress);

module.exports = router;