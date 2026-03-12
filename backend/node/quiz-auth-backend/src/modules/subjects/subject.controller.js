const subjectService = require('../../services/subject.service');

async function listSubjects(req, res, next) {
    try {
        const examId = (req.query.examId || '').toString().trim();
        if (!examId) {
            return res.status(400).json({
                error: {
                    code: 400,
                    message: 'examId query parameter is required'
                }
            });
        }

        const subjects = await subjectService.getByExamId(examId);
        return res.json({ subjects });
    } catch (err) {
        return next(err);
    }
}

module.exports = { listSubjects };
