const questionRepo = require('../repositories/question.repository');
const redisService = require('./redis.service');
const { randomFloat } = require('../utils/random');
const config = require('../config');

class QuizService {
    // returns a question (lean) or null if exhausted
    async getNextQuestion({ userId, examId, subjectId, difficulty }) {
        const filters = { examId, subjectId, difficulty, status: 'published' };
        const maxRetries = config.quizMaxRetries || 12;

        for (let attempt = 0; attempt < maxRetries; attempt++) {
            const r = randomFloat();
            const candidate = await questionRepo.getNextQuestionCandidate(filters, r);
            if (!candidate) continue;

            const seen = await redisService.isSeen(userId, examId, subjectId, difficulty, candidate.questionIndex);
            if (seen === 0) {
                await redisService.markSeen(userId, examId, subjectId, difficulty, candidate.questionIndex);
                // strip fields you don't want to send (if any)
                return candidate;
            }

            // otherwise loop and try again
        }

        // exhausted or not found unseen after retries
        return null;
    }

    async submitAnswer({ userId, questionId, selectedOptions }) {
        // check correctness
        const q = await questionRepo.findByQuestionIndex(questionId) || await questionRepo.findById(questionId);
        if (!q) throw new Error('Question not found');

        const correctSet = new Set(q.correctAnswer);
        const selectedSet = new Set(selectedOptions);
        const isCorrect = selectedSet.size === correctSet.size && [...selectedSet].every(x => correctSet.has(x));

        return { isCorrect, question: q };
    }
}

module.exports = new QuizService();