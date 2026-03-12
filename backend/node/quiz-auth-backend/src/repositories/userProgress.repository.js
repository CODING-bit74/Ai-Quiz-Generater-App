const UserProgress = require('../models/userProgress.model');

class UserProgressRepository {
    async upsertProgress(userId, examId, subjectId, difficulty, incTotal = 1, incCorrect = 0) {
        return UserProgress.findOneAndUpdate(
            { userId, examId, subjectId, difficulty },
            { $inc: { totalSolved: incTotal, correctAnswers: incCorrect } },
            { upsert: true, new: true }
        );
    }

    async getProgress(userId, examId, subjectId, difficulty) {
        return UserProgress.findOne({ userId, examId, subjectId, difficulty }).lean();
    }
}

module.exports = new UserProgressRepository();