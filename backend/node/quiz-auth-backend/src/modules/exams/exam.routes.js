const express = require('express');
const router = express.Router();
const controller = require('./exam.controller');

router.get('/', controller.listExams);

module.exports = router;
