const examService = require('../../services/exam.service');

async function listExams(req, res, next) {
    try {
        const exams = await examService.getAllExams();
        res.json({ exams });
    } catch (err) {
        next(err);
    }
}

module.exports = { listExams };
