const rateLimit = require('express-rate-limit');

module.exports = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX || '10', 10),
    message: { error: { message: 'Too many requests' } }
});