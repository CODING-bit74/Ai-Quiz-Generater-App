const mongoose = require('mongoose');

const OptionSchema = new mongoose.Schema({
    id: { type: String, required: true },
    text: { type: String, required: true }
}, { _id: false });

const QuestionSchema = new mongoose.Schema({
    questionIndex: { type: Number, unique: true, index: true, required: true }, // assigned via counter service
    examId: { type: String, index: true, required: true },
    subjectId: { type: String, index: true, required: true },
    topicId: { type: String, index: true, required: false },
    year: { type: Number },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], index: true, required: true },
    isPreviousYear: { type: Boolean, default: false },
    text: { type: String, required: true },
    options: { type: [OptionSchema], required: true },
    correctAnswer: { type: [String], required: true }, // array of option ids
    explanation: { type: String, default: '' },
    random: { type: Number, default: Math.random, index: true },
    status: { type: String, enum: ['draft', 'published'], default: 'draft' }
}, { timestamps: true });

// compound index for fast random selection
QuestionSchema.index({ examId: 1, subjectId: 1, difficulty: 1, random: 1 });

module.exports = mongoose.model('Question', QuestionSchema);