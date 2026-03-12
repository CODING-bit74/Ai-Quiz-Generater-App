const questionRepo = require('../repositories/question.repository');
const counterService = require('./counter.service');
const config = require('../config');

class QuestionService {
    // create a question and assign safe, auto-incremented questionIndex and random
    async createQuestion(payload) {
        // get next index
        const idx = await counterService.getNextSequence(config.questionIndexCounterName);
        const doc = {
            ...payload,
            questionIndex: idx,
            random: Math.random()
        };
        const q = await questionRepo.createQuestion(doc);
        return q;
    }

    async getByIndex(questionIndex) {
        return questionRepo.findByQuestionIndex(questionIndex);
    }
}

module.exports = new QuestionService();