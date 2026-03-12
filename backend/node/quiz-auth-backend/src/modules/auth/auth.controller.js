const authService = require('./auth.service');
const { verifyEmailToken } = require("./auth.verification");
const User = require("../../models/user.model");

function escapeHtml(value) {
    return String(value ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function renderResetPasswordPage({
    token = "",
    statusMessage = "",
    isError = false
} = {}) {
    const safeToken = token.toString().trim();
    const hasToken = safeToken.length > 0;
    const escapedToken = escapeHtml(safeToken);
    const deepLink = hasToken
        ? `quizapp://reset-password?token=${encodeURIComponent(safeToken)}`
        : "";
    const escapedDeepLink = escapeHtml(deepLink);
    const escapedStatus = escapeHtml(statusMessage);
    const statusColor = isError ? "#b91c1c" : "#166534";

    return `
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Reset Password</title>
</head>
<body style="font-family:Arial,sans-serif;padding:24px;line-height:1.5;max-width:560px;margin:0 auto;">
  <h2 style="margin-bottom:8px;">Reset Password</h2>
  <p style="margin-top:0;color:#444;">Set a new password for your account.</p>
  ${hasToken ? `
  <p style="margin:14px 0;">
    <a href="${escapedDeepLink}" style="display:inline-block;padding:10px 16px;background:#2563eb;color:#fff;text-decoration:none;border-radius:8px;font-weight:600;">Open In Quiz App</a>
  </p>
  <p style="font-size:12px;color:#555;margin-top:0;">If app open fails on this browser/device, use the form below.</p>
  ` : `
  <p style="color:#b91c1c;font-size:14px;">Missing reset token. Open the full reset link from your email.</p>
  `}

  ${escapedStatus ? `<p style="font-size:14px;color:${statusColor};font-weight:600;">${escapedStatus}</p>` : ""}

  ${hasToken ? `
  <form method="post" action="/api/auth/open-reset-password" style="display:flex;flex-direction:column;gap:10px;margin-top:16px;">
    <input type="hidden" name="token" value="${escapedToken}" />

    <label for="newPassword" style="font-size:14px;font-weight:600;">New password</label>
    <input id="newPassword" name="newPassword" type="password" minlength="6" required style="padding:10px;border:1px solid #cbd5e1;border-radius:8px;font-size:14px;" />

    <label for="confirmPassword" style="font-size:14px;font-weight:600;">Confirm password</label>
    <input id="confirmPassword" name="confirmPassword" type="password" minlength="6" required style="padding:10px;border:1px solid #cbd5e1;border-radius:8px;font-size:14px;" />

    <button type="submit" style="margin-top:8px;padding:10px 16px;background:#2563eb;color:#fff;border:none;border-radius:8px;font-weight:600;cursor:pointer;">Save New Password</button>
  </form>
  ` : ""}
</body>
</html>`;
}

async function verifyEmail(req, res, next) {
    try {
        const { token } = req.query;

        const decoded = verifyEmailToken(token);

        await User.updateOne(
            { _id: decoded.userId },
            { isEmailVerified: true }
        );

        res.json({ message: "Email verified successfully" });

    } catch (err) {
        res.status(400).json({ error: "Invalid or expired token" });
    }
}

async function emailVerificationStatus(req, res, next) {
    try {
        const { email } = req.query;

        if (!email) {
            return res.status(400).json({ message: "Email is required" });
        }

        const user = await User.findOne({ email }).select("email isEmailVerified");
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        return res.json({
            email: user.email,
            isEmailVerified: user.isEmailVerified === true
        });
    } catch (err) {
        next(err);
    }
}

async function register(req, res, next) {
    try {
        const { email, password, name } = req.body;
        const result = await authService.register({ email, password, name });
        return res.status(201).json(result);
    } catch (err) { next(err); }
}

async function login(req, res, next) {
    try {
        const { email, password, deviceInfo } = req.body;
        const result = await authService.login({ email, password, deviceInfo });
        return res.json(result);
    } catch (err) { next(err); }
}

async function refresh(req, res, next) {
    try {
        const { refreshToken, deviceInfo } = req.body;
        const result = await authService.refresh({ refreshToken, deviceInfo });
        return res.json(result);
    } catch (err) { next(err); }
}

async function logout(req, res, next) {
    try {
        const { refreshToken } = req.body;
        await authService.logout({ refreshToken });
        return res.status(204).send();
    } catch (err) { next(err); }
}

async function forgotPassword(req, res, next) {

    try {

        const { email } = req.body;

        const result =
            await authService.forgotPassword(email);

        res.json(result);

    } catch (err) {
        next(err);
    }
}

async function resetPassword(req, res, next) {

    try {

        const { token, newPassword } = req.body;

        const result =
            await authService.resetPassword(token, newPassword);

        res.json(result);

    } catch (err) {
        next(err);
    }
}
async function resendVerificationEmail(req, res, next) {
    try {

        const { email } = req.body;

        const result =
            await authService.resendVerificationEmail(email);

        res.json(result);

    } catch (err) {
        next(err);
    }
}

function openResetPasswordLink(req, res) {
    const token = (req.query.token || "").toString().trim();

    if (!token) {
        return res.status(400).send(
            renderResetPasswordPage({
                statusMessage: "Missing reset token. Open the full reset link from your email.",
                isError: true
            })
        );
    }

    return res.status(200).send(renderResetPasswordPage({ token }));
}

async function submitOpenResetPasswordLink(req, res) {
    const token = (req.body.token || "").toString().trim();
    const newPassword = (req.body.newPassword || "").toString().trim();
    const confirmPassword = (req.body.confirmPassword || "").toString().trim();

    if (!token) {
        return res.status(400).send(
            renderResetPasswordPage({
                statusMessage: "Missing reset token. Open the full reset link from your email.",
                isError: true
            })
        );
    }

    if (newPassword.length < 6) {
        return res.status(400).send(
            renderResetPasswordPage({
                token,
                statusMessage: "Password must be at least 6 characters.",
                isError: true
            })
        );
    }

    if (newPassword !== confirmPassword) {
        return res.status(400).send(
            renderResetPasswordPage({
                token,
                statusMessage: "Passwords do not match.",
                isError: true
            })
        );
    }

    try {
        await authService.resetPassword(token, newPassword);
        return res.status(200).send(
            renderResetPasswordPage({
                statusMessage: "Password reset successful. You can now log in."
            })
        );
    } catch (err) {
        return res.status(400).send(
            renderResetPasswordPage({
                token,
                statusMessage: err.message || "Failed to reset password. Please try again.",
                isError: true
            })
        );
    }
}

module.exports = {
    register,
    login,
    refresh,
    logout,
    verifyEmail,
    emailVerificationStatus,
    forgotPassword,
    resetPassword,
    resendVerificationEmail,
    openResetPasswordLink,
    submitOpenResetPasswordLink
};
