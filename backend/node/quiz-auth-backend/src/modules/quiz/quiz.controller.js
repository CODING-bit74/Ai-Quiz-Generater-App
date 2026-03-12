const quizService = require('../../services/quiz.service');
const progressService = require('../../services/progress.service');

async function getNext(req, res, next) {
    try {
        const { examId, subjectId, difficulty } = req.query;
        const userId = req.user.id;
        const q = await quizService.getNextQuestion({ userId, examId, subjectId, difficulty });
        if (!q) return res.status(204).send();
        res.json({ question: q });
    } catch (err) {
        next(err);
    }
}

async function submit(req, res, next) {
    try {
        const userId = req.user.id;
        const { questionIndex, selectedOptions, examId, subjectId, difficulty } = req.body;

        const { isCorrect, question } = await quizService.submitAnswer({
            userId, questionId: questionIndex, selectedOptions
        });

        // update progress
        await progressService.updateProgress({ userId, examId, subjectId, difficulty, correct: isCorrect });

        res.json({ correct: isCorrect, explanation: question.explanation });
    } catch (err) {
        next(err);
    }
}

module.exports = { getNext, submit };