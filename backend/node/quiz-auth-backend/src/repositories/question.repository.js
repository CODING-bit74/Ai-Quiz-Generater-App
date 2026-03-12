const Question = require('../models/question.model');

class QuestionRepository {
    async createQuestion(doc) {
        return Question.create(doc);
    }

    async findByQuestionIndex(index) {
        return Question.findOne({ questionIndex: index });
    }

    // Get one candidate with random >= r, falling back to <= r
    async getNextQuestionCandidate({ examId, subjectId, difficulty, status = 'published' }, r) {
        const baseFilter = { examId, subjectId, difficulty, status };
        // first try random >= r, ascending (closest bigger)
        let doc = await Question.findOne({ ...baseFilter, random: { $gte: r } }).sort({ random: 1 }).lean();
        if (doc) return doc;
        // fallback: random <= r, ascending (small values)
        doc = await Question.findOne({ ...baseFilter, random: { $lte: r } }).sort({ random: 1 }).lean();
        return doc;
    }

    // administrative find / pagination
    async list(filter, options = {}) {
        return Question.find(filter).limit(options.limit || 50).skip(options.skip || 0);
    }
}

module.exports = new QuestionRepository();