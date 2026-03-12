// central config object
require('dotenv').config();

module.exports = {
    port: process.env.PORT || 4000,
    nodeEnv: process.env.NODE_ENV || 'development',
    mongoUri: process.env.MONGO_URI,
    redisUrl: process.env.REDIS_URL,
    jwtSecret: process.env.JWT_ACCESS_SECRET,
    jwtExpires: process.env.JWT_ACCESS_EXPIRES || '15m',
    bcryptRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS || '12', 10),
    questionIndexCounterName: process.env.QUESTION_INDEX_COUNTER_NAME || 'questionIndex',
    quizMaxRetries: parseInt(process.env.QUIZ_MAX_RETRIES || '12', 10)
};