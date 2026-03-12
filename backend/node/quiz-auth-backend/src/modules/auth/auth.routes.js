const express = require('express');
const router = express.Router();
const controller = require('./auth.controller');

router.post('/register', controller.register);
router.post('/login', controller.login);
router.post('/refresh', controller.refresh);
router.post('/logout', controller.logout);
router.get("/verify-email", controller.verifyEmail);
router.get("/email-verification-status", controller.emailVerificationStatus);
router.get("/open-reset-password", controller.openResetPasswordLink);
router.post("/open-reset-password", controller.submitOpenResetPasswordLink);
router.post("/forgot-password", controller.forgotPassword);
router.post("/reset-password", controller.resetPassword);
router.post("/resend-verification", controller.resendVerificationEmail);

module.exports = router;
