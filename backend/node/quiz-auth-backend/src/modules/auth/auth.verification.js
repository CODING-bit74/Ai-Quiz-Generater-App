const jwt = require("jsonwebtoken");

function generateEmailVerificationToken(userId) {
    return jwt.sign(
        { userId },
        process.env.EMAIL_VERIFY_SECRET,
        { expiresIn: "10m" }
    );
}

function verifyEmailToken(token) {
    return jwt.verify(token, process.env.EMAIL_VERIFY_SECRET);
}

module.exports = {
    generateEmailVerificationToken,
    verifyEmailToken
};