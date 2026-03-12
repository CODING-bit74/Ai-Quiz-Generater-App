const express = require('express');
const router = express.Router();
const controller = require('./quiz.controller');

const auth = require('../../middlewares/auth.middleware');

router.get('/next', auth.requireAuth, controller.getNext);
router.post('/submit', auth.requireAuth, controller.submit);

module.exports = router;