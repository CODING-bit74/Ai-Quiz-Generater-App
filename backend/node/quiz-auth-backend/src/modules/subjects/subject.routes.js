const express = require('express');
const router = express.Router();
const controller = require('./subject.controller');

router.get('/', controller.listSubjects);

module.exports = router;
