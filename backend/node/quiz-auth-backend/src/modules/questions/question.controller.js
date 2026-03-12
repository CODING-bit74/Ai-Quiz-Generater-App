const questionService = require('../../services/question.service');
const ApiError = require('../../utils/ApiError');

async function createQuestion(req, res, next) {
    try {
        const payload = req.body;
        // validation should have been done already
        const q = await questionService.createQuestion(payload);
        res.status(201).json({ question: q });
    } catch (err) {
        next(err);
    }
}

module.exports = { createQuestion };