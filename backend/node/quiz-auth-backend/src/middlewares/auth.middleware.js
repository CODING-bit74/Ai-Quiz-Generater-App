const jwt = require("jsonwebtoken");
const User = require("../models/user.model");

async function requireAuth(req, res, next) {

    try {

        const authHeader = req.headers.authorization;

        if (!authHeader) {
            return res.status(401).json({
                error: { message: "Authorization header missing" }
            });
        }

        const token = authHeader.split(" ")[1];

        if (!token) {
            return res.status(401).json({
                error: { message: "Token missing" }
            });
        }

        const decoded = jwt.verify(
            token,
            process.env.JWT_ACCESS_SECRET
        );

        const user = await User.findById(decoded.sub).lean();

        if (!user) {
            return res.status(401).json({
                error: { message: "Invalid token user" }
            });
        }

        req.user = {
            id: user._id,
            roles: user.roles || ["user"]
        };

        next();

    } catch (err) {

        return res.status(401).json({
            error: { message: "Invalid or expired token" }
        });

    }

}

module.exports = {
    requireAuth
};