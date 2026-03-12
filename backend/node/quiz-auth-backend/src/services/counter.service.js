const Counter = require('../models/counter.model');

class CounterService {
    // uses atomic findOneAndUpdate to increment and returns new seq
    async getNextSequence(name) {
        const res = await Counter.findOneAndUpdate(
            { _id: name },
            { $inc: { seq: 1 } },
            { new: true, upsert: true, useFindAndModify: false }
        );
        return res.seq;
    }
}

module.exports = new CounterService();