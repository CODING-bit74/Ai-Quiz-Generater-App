const bcrypt = require('bcryptjs');
const authRepo = require('./auth.repository');
const tokens = require('./auth.tokens');
const User = require("../../models/user.model");
const crypto = require("crypto");
const { generateResetToken } = require("./auth.reset");
const { sendEmail } = require("../../services/mail.service");
const { generateEmailVerificationToken } = require("./auth.verification");
const { hashToken, generateRefreshTokenRaw, signAccessToken, getRefreshExpiresAt } = tokens;
const BCRYPT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS || '12', 10);

// register
async function register({ email, password, name }) {

    // 1️⃣ Check if user exists
    const existing = await authRepo.findByEmail(email);
    if (existing)
        throw new Error("Email already in use");


    // 2️⃣ Hash password
    const passHash = await bcrypt.hash(password, BCRYPT_ROUNDS);


    // 3️⃣ Create user (isEmailVerified defaults to false)
    const user = await User.create({
        name,
        email,
        password: passHash

    });


    // ✅ 4️⃣ Generate email verification token
    const verifyToken = generateEmailVerificationToken(user._id);


    // ✅ 5️⃣ Create verification link
    const verifyLink =
        `${process.env.CLIENT_URL}/verify-email?token=${verifyToken}`;


    // ✅ 6️⃣ Send verification email
    await sendEmail(
        user.email,
        "Verify your email",
        `
      <h2>Welcome to Quiz App</h2>
      <p>Please verify your email by clicking the link below:</p>
      <a href="${verifyLink}">Verify Email</a>
      <p>This link expires in 24 hours.</p>
    `
    );


    // 7️⃣ Generate login tokens (optional — you can also block login until verified)
    const accessToken = signAccessToken(user);

    const rawRefresh = generateRefreshTokenRaw();

    const refreshHash = hashToken(rawRefresh);

    const expiresAt = getRefreshExpiresAt();


    // 8️⃣ Save refresh token in DB
    await authRepo.saveRefreshToken(
        user._id,
        {
            tokenHash: refreshHash,
            expiresAt,
            deviceInfo: null
        }
    );


    // 9️⃣ Return response
    return {
        user: {
            id: user._id,
            email: user.email,
            name: user.name,
            isEmailVerified: user.isEmailVerified
        },
        accessToken,
        refreshToken: rawRefresh
    };

}



// login
async function login({ email, password, deviceInfo }) {

    const user = await authRepo.findByEmail(email);

    if (!user.isEmailVerified) {
        throw new Error("Please verify your email first");
    }

    if (!user) throw new Error('Invalid credentials');

    // lockout check omitted for brevity

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
        // increment failed attempts etc.
        throw new Error('Invalid credentials');
    }

    const accessToken = signAccessToken(user);
    const rawRefresh = generateRefreshTokenRaw();
    const refreshHash = hashToken(rawRefresh);
    const expiresAt = getRefreshExpiresAt();

    await authRepo.saveRefreshToken(user._id, { tokenHash: refreshHash, expiresAt, deviceInfo });

    return { user: { id: user._id, email: user.email }, accessToken, refreshToken: rawRefresh };
}

// refresh (rotation)
async function refresh({ refreshToken, deviceInfo }) {
    if (!refreshToken) throw new Error('Missing refresh token');

    const presentedHash = hashToken(refreshToken);

    const user = await authRepo.findByRefreshHash(presentedHash);
    if (!user) {
        // reuse detection: cannot find presented token
        throw new Error('Refresh token invalid or reused');
    }

    // Remove old token entry
    await authRepo.removeRefreshHash(user._id, presentedHash);

    // Issue new refresh token
    const newRaw = generateRefreshTokenRaw();
    const newHash = hashToken(newRaw);
    const expiresAt = getRefreshExpiresAt();
    await authRepo.saveRefreshToken(user._id, { tokenHash: newHash, expiresAt, deviceInfo });

    const accessToken = signAccessToken(user);

    return { accessToken, refreshToken: newRaw };
}

// logout - delete single refresh token
async function logout({ refreshToken }) {
    const presentedHash = hashToken(refreshToken);
    const user = await authRepo.findByRefreshHash(presentedHash);
    if (!user) return;
    await authRepo.removeRefreshHash(user._id, presentedHash);
}


async function forgotPassword(email) {

    const user = await User.findOne({ email });

    if (!user)
        throw new Error("User not found");

    const { rawToken, tokenHash } =
        generateResetToken();

    const expires =
        new Date(Date.now() + 15 * 60 * 1000);

    user.resetPasswordTokenHash = tokenHash;
    user.resetPasswordExpires = expires;

    await user.save();

    const deepLink =
        `quizapp://reset-password?token=${rawToken}`;
    const authBaseUrl =
        (process.env.CLIENT_URL || "").replace(/\/+$/, "");
    const resetLink = authBaseUrl
        ? `${authBaseUrl}/open-reset-password?token=${encodeURIComponent(rawToken)}`
        : deepLink;

    await sendEmail(
        user.email,
        "Reset Password",
        `
    <h3>Password Reset</h3>
    <p>Click the button below to reset your password:</p>
    <p>
      <a
        href="${resetLink}"
        style="display:inline-block;padding:10px 16px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:600;"
      >
        Reset Password
      </a>
    </p>
    <p>If the button does not open the app, copy this link and open it manually:</p>
    <p>${deepLink}</p>
    <p>Expires in 15 minutes.</p>
    `
    );

    return {
        message: "Reset link sent"
    };
}

async function resetPassword(token, newPassword) {

    const tokenHash =
        crypto.createHash("sha256")
            .update(token)
            .digest("hex");

    const user = await User.findOne({
        resetPasswordTokenHash: tokenHash,
        resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user)
        throw new Error("Invalid or expired token");

    const hash =
        await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

    user.password = hash;

    user.resetPasswordTokenHash = null;
    user.resetPasswordExpires = null;

    await user.save();

    return {
        message: "Password reset successful"
    };
}



async function resendVerificationEmail(email) {

    const user = await User.findOne({ email });

    if (!user)
        throw new Error("User not found");

    if (user.isEmailVerified)
        throw new Error("Email already verified");


    // generate new token
    const verifyToken =
        generateEmailVerificationToken(user._id);


    const verifyLink =
        `${process.env.CLIENT_URL}/verify-email?token=${verifyToken}`;


    await sendEmail(
        user.email,
        "Verify your email",
        `
      <h2>Email Verification</h2>
      <p>Click below to verify your email:</p>
      <a href="${verifyLink}">Verify Email</a>
      <p>This link expires in 10 Min.</p>
    `
    );


    return {
        message: "Verification email sent successfully"
    };

}
module.exports = { register, login, refresh, logout, forgotPassword, resendVerificationEmail, resetPassword };
