// simple role checking middleware factory
function isAdmin(req, res, next) {
    const user = req.user;
    if (!user || !user.roles || !user.roles.includes('admin')) {
        return res.status(403).json({ error: { message: 'Forbidden' } });
    }
    next();
}

module.exports = { isAdmin };