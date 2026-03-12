const mongoose = require('mongoose');

const ExamSchema = new mongoose.Schema({
    id: { type: String, unique: true, index: true, required: true },
    name: { type: String, required: true },
    description: { type: String, default: '' }
}, { timestamps: true });

module.exports = mongoose.model('Exam', ExamSchema);