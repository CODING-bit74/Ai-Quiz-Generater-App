const redis = require('../config/redis');
const { seenKey } = require('../constants/redis-keys');

class RedisService {
    // isSeen returns 0 or 1
    async isSeen(userId, examId, subjectId, difficulty, questionIndex) {
        const key = seenKey(userId, examId, subjectId, difficulty);
        const bit = await redis.getbit(key, parseInt(questionIndex, 10));
        return parseInt(bit, 10);
    }

    async markSeen(userId, examId, subjectId, difficulty, questionIndex) {
        const key = seenKey(userId, examId, subjectId, difficulty);
        // set TTL in seconds if you want TTL, e.g. expire after 7 days
        await redis.setbit(key, parseInt(questionIndex, 10), 1);
        return true;
    }

    async countSeen(userId, examId, subjectId, difficulty) {
        const key = seenKey(userId, examId, subjectId, difficulty);
        const count = await redis.bitcount(key);
        return count;
    }

    async resetSeen(userId, examId, subjectId, difficulty) {
        const key = seenKey(userId, examId, subjectId, difficulty);
        await redis.del(key);
    }
}

module.exports = new RedisService();