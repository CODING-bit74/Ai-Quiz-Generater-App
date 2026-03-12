const progressRepo = require('../repositories/userProgress.repository');

class ProgressService {
    async updateProgress({ userId, examId, subjectId, difficulty, correct }) {
        const incCorrect = correct ? 1 : 0;
        const res = await progressRepo.upsertProgress(userId, examId, subjectId, difficulty, 1, incCorrect);
        return res;
    }

    async getProgress(userId, examId, subjectId, difficulty) {
        return progressRepo.getProgress(userId, examId, subjectId, difficulty);
    }
}

module.exports = new ProgressService();