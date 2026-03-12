require('dotenv').config();

const mongoose = require('mongoose');

const connectDB = require('../config/db');
const counterService = require('../services/counter.service');

const Question = require('../models/question.model');
const Exam = require('../models/exam.model');
const Subject = require('../models/subject.model');
const Topic = require('../models/topic.model');


async function seed() {

    await connectDB();

    console.log("Connected to DB");

    // create exam
    const exam = await Exam.create({
        id: "exam1",
        name: "Sample Exam",
        description: "Demo exam"
    });

    console.log("Exam created");


    // create subject
    const subject = await Subject.create({
        examId: exam.id,
        id: "math",
        name: "Mathematics"
    });

    console.log("Subject created");


    // create topic
    const topic = await Topic.create({
        id: "algebra",
        name: "Algebra",
        subjectId: subject.id
    });

    console.log("Topic created");


    const questions = [];

    for (let i = 1; i <= 1000; i++) {

        const questionIndex =
            await counterService.getNextSequence("questionIndex");

        questions.push({
            questionIndex,
            examId: exam.id,
            subjectId: subject.id,
            topicId: topic.id,
            year: 2024,
            difficulty: "easy",
            isPreviousYear: false,

            text: `What is ${i} + ${i}?`,

            options: [
                { id: "A", text: `${i}` },
                { id: "B", text: `${i * 2}` },
                { id: "C", text: `${i + 1}` },
                { id: "D", text: `${i - 1}` }
            ],

            correctAnswer: ["B"],

            explanation: "Basic addition",

            random: Math.random(),

            status: "published"
        });
    }

    await Question.insertMany(questions);

    console.log("1000 Questions inserted");

    process.exit(0);
}

seed();
