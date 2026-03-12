const Subject = require('../models/subject.model');
const Question = require('../models/question.model');

class SubjectRepository {
    async listByExamId(examId) {
        return Subject.find(
            { examId },
            { _id: 0, examId: 1, id: 1, name: 1 }
        )
            .sort({ name: 1 })
            .lean();
    }

    async deriveByExamIdFromQuestions(examId) {
        const subjectIds = await Question.distinct('subjectId', { examId });
        if (!subjectIds.length) {
            return [];
        }

        const existingNames = await Subject.find(
            { id: { $in: subjectIds } },
            { _id: 0, id: 1, name: 1 }
        ).lean();

        const nameById = new Map(existingNames.map((item) => [item.id, item.name]));

        return subjectIds.map((subjectId) => ({
            examId,
            id: subjectId,
            name: nameById.get(subjectId) || subjectId
        }));
    }

    async upsertMany(subjects) {
        if (!subjects.length) {
            return;
        }

        await Subject.bulkWrite(
            subjects.map((subject) => ({
                updateOne: {
                    filter: { examId: subject.examId, id: subject.id },
                    update: { $setOnInsert: subject },
                    upsert: true
                }
            }))
        );
    }
}

module.exports = new SubjectRepository();
