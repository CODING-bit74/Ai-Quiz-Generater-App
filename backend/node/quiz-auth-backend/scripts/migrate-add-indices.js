// Run this once to ensure indexes exist
const mongoose = require('mongoose');
require('dotenv').config();
const Question = require('../models/question.model');
const UserProgress = require('../models/userProgress.model');

async function run() {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to DB');
    try {
        await Question.createIndexes();
        console.log('Question indexes created');
        await UserProgress.createIndexes();
        console.log('UserProgress indexes created');
    } catch (err) {
        console.error(err);
    } finally {
        process.exit(0);
    }
}

run();