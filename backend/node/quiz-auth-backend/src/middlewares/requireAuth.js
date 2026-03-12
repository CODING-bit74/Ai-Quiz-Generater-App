const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

module.exports = async function requireAuth(req, res, next) {
    try {
        const auth = req.headers.authorization;
        if (!auth) return res.status(401).json({ error: { message: 'Missing token' } });
        const token = auth.split(' ')[1];
        const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
        const user = await User.findById(payload.sub).lean();
        if (!user) return res.status(401).json({ error: { message: 'Invalid token' } });
        req.user = user;
        next();
    } catch (err) {
        return res.status(401).json({ error: { message: 'Invalid/Expired token' } });
    }
};