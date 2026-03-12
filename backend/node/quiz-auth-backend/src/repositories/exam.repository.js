const Exam = require('../models/exam.model');

class ExamRepository {
    async listAll() {
        return Exam.find({}, { _id: 0, id: 1, name: 1, description: 1 })
            .sort({ createdAt: 1 })
            .lean();
    }
}

module.exports = new ExamRepository();
