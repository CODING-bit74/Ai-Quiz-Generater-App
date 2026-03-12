const Redis = require('ioredis');
const config = require('./index');

let redisClient;

function createRedis() {
    if (redisClient) return redisClient;
    redisClient = new Redis(config.redisUrl);
    redisClient.on('connect', () => console.log('✅ Redis connected'));
    redisClient.on('error', (err) => console.error('❌ Redis error', err));
    return redisClient;
}

module.exports = createRedis();