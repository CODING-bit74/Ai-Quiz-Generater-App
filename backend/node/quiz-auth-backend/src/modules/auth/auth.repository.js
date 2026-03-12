const User = require('../../models/user.model');

async function findByEmail(email) {
    return User.findOne({ email }).lean();
}

async function findById(id) {
    return User.findById(id);
}

async function findByRefreshHash(hash) {
    return User.findOne({ 'refreshTokens.tokenHash': hash });
}

async function saveRefreshToken(userId, tokenObj) {
    return User.updateOne({ _id: userId }, { $push: { refreshTokens: tokenObj } });
}

async function removeRefreshHash(userId, hash) {
    return User.updateOne({ _id: userId }, { $pull: { refreshTokens: { tokenHash: hash } } });
}

async function removeAllRefreshTokens(userId) {
    return User.updateOne({ _id: userId }, { $set: { refreshTokens: [] } });
}

// other helpers: createUser, incrementFailedAttempts, resetFailedAttempts

module.exports = {
    findByEmail, findById, findByRefreshHash, saveRefreshToken, removeRefreshHash, removeAllRefreshTokens
};