const progressService = require('../../services/progress.service');

async function getProgress(req, res, next) {
    try {
        const userId = req.user.id;
        const { examId, subjectId, difficulty } = req.query;
        const data = await progressService.getProgress(userId, examId, subjectId, difficulty);
        res.json({ progress: data });
    } catch (err) {
        next(err);
    }
}

module.exports = { getProgress };