const examRepository = require('../repositories/exam.repository');

class ExamService {
    async getAllExams() {
        return examRepository.listAll();
    }
}

module.exports = new ExamService();
