const mongoose = require("mongoose");

async function connectDB() {
    try {
        const uri = process.env.MONGO_URI;

        await mongoose.connect(uri);

        console.log("✅ MongoDB connected");
    } catch (error) {
        console.error("❌ Failed to connect to DB", error);
        process.exit(1);
    }
}

module.exports = connectDB;