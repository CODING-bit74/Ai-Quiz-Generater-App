const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET;
const ACCESS_EXPIRES = process.env.JWT_ACCESS_EXPIRES || '15m';
const REFRESH_BYTES = parseInt(process.env.REFRESH_TOKEN_BYTES || '64', 10);
const REFRESH_EXPIRES_DAYS = parseInt(process.env.REFRESH_TOKEN_EXPIRES_DAYS || '14', 10);

function signAccessToken(user) {
    const payload = {
        sub: user._id.toString(),
        roles: user.roles,
        jti: uuidv4()
    };
    return jwt.sign(payload, ACCESS_SECRET, { expiresIn: ACCESS_EXPIRES });
}

function generateRefreshTokenRaw() {
    return crypto.randomBytes(REFRESH_BYTES).toString('hex');
}

function hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
}

function getRefreshExpiresAt() {
    return new Date(Date.now() + REFRESH_EXPIRES_DAYS * 24 * 60 * 60 * 1000);
}

module.exports = { signAccessToken, generateRefreshTokenRaw, hashToken, getRefreshExpiresAt };