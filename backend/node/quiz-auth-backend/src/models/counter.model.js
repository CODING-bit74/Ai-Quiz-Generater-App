const mongoose = require('mongoose');

const CounterSchema = new mongoose.Schema({
    _id: { type: String, required: true }, // counter name e.g. "questionIndex"
    seq: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('Counter', CounterSchema);