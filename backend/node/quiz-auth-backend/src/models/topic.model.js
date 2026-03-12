const mongoose = require('mongoose');

const TopicSchema = new mongoose.Schema({
    id: { type: String, required: true },
    name: { type: String, required: true },
    subjectId: { type: String, index: true, required: true }
}, { timestamps: true });

module.exports = mongoose.model('Topic', TopicSchema);