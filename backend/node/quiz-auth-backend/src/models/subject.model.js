const mongoose = require('mongoose');

const SubjectSchema = new mongoose.Schema({
    examId: { type: String, index: true, required: true },
    id: { type: String, required: true },
    name: { type: String, required: true }
}, { timestamps: true });

SubjectSchema.index({ examId: 1, id: 1 }, { unique: true });

module.exports = mongoose.model('Subject', SubjectSchema);
