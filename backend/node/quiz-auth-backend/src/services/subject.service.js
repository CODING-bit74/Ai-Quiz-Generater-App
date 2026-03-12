const subjectRepository = require('../repositories/subject.repository');

class SubjectService {
    async getByExamId(examId) {
        let subjects = await subjectRepository.listByExamId(examId);
        if (subjects.length > 0) {
            return subjects;
        }

        // Backward compatibility: derive subjects for older DBs where examId was missing.
        subjects = await subjectRepository.deriveByExamIdFromQuestions(examId);
        await subjectRepository.upsertMany(subjects);
        return subjects;
    }
}

module.exports = new SubjectService();
