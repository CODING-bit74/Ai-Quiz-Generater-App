const mongoose = require('mongoose');

const UserProgressSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    examId: { type: String, required: true },
    subjectId: { type: String, required: true },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], required: true },
    totalSolved: { type: Number, default: 0 },
    correctAnswers: { type: Number, default: 0 }
}, { timestamps: true });

UserProgressSchema.index({ userId: 1, examId: 1, subjectId: 1, difficulty: 1 }, { unique: true });

module.exports = mongoose.model('UserProgress', UserProgressSchema);