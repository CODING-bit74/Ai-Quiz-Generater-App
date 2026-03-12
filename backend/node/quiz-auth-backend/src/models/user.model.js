const mongoose = require('mongoose');

const RefreshTokenSchema = new mongoose.Schema({
    tokenHash: { type: String, required: true },
    createdAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, required: true },
    deviceInfo: { type: String, default: null },
    lastUsedAt: { type: Date, default: null }
}, { _id: false });

const UserSchema = new mongoose.Schema({
    name: { type: String, default: null },
    email: { type: String, unique: true, index: true, required: true },
    password: { type: String, default: null },
    provider: { type: String, enum: ['local', 'google', 'apple'], default: 'local' },
    providerId: { type: String, index: true, sparse: true },
    roles: { type: [String], default: ['user'] },
    plan: {
        type: { type: String, enum: ['free', 'premium'], default: 'free' },
        expiresAt: { type: Date, default: null }
    },
    isEmailVerified: { type: Boolean, default: false },
    refreshTokens: [RefreshTokenSchema],
    failedLoginAttempts: { type: Number, default: 0 },
    lockUntil: { type: Date, default: null },

    resetPasswordTokenHash: {
        type: String,
        default: null
    },
    resetPasswordExpires: {
        type: Date,
        default: null
    }
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);