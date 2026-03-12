const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const cookieParser = require('cookie-parser');

// existing auth routes
const authRoutes = require('./modules/auth/auth.routes');

// NEW: quiz system routes
const examRoutes = require('./modules/exams/exam.routes');
const subjectRoutes = require('./modules/subjects/subject.routes');
const questionRoutes = require('./modules/questions/question.routes');
const quizRoutes = require('./modules/quiz/quiz.routes');
const progressRoutes = require('./modules/progress/progress.routes');

// error handler
const errorHandler = require('./middlewares/errorHandler');

// initialize Redis connection (important)
require('./config/redis');

const app = express();


// =====================
// Security Middlewares
// =====================
app.use(helmet());

app.use(cors({
    origin: true, // later restrict to Flutter app domain
    credentials: true
}));


// =====================
// Body Parsers
// =====================
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());


// =====================
// Logger
// =====================
app.use(morgan('dev'));


// =====================
// Routes
// =====================

// Auth routes (already implemented)
app.use('/api/auth', authRoutes);

// Exam routes (choose your path)
app.use('/api/exams', examRoutes);

// Subject routes (filtered by exam)
app.use('/api/subjects', subjectRoutes);

// Question admin routes
app.use('/api/questions', questionRoutes);

// Quiz routes (get next question, submit answer)
app.use('/api/quiz', quizRoutes);

// Progress routes
app.use('/api/progress', progressRoutes);


// =====================
// Health check
// =====================
app.get('/health', (req, res) => {
    res.json({
        ok: true,
        service: 'quiz-backend',
        timestamp: new Date().toISOString()
    });
});


// =====================
// Error handler (MUST be last)
// =====================
app.use(errorHandler);


module.exports = app;
