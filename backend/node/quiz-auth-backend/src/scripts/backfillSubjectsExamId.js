require('dotenv').config();

const connectDB = require('../config/db');
const Subject = require('../models/subject.model');
const Question = require('../models/question.model');

async function ensureSubjectIndexes() {
    const collection = Subject.collection;
    const indexes = await collection.indexes();
    const legacyIdIndex = indexes.find((idx) => idx.name === 'id_1');

    if (legacyIdIndex && legacyIdIndex.unique) {
        console.log('Dropping legacy unique index subjects.id_1');
        await collection.dropIndex('id_1');
    }

    // Align DB indexes with current schema (examId + id unique).
    await Subject.syncIndexes();
}

async function run() {
    await connectDB();
    await ensureSubjectIndexes();

    const pairs = await Question.aggregate([
        {
            $group: {
                _id: { examId: '$examId', subjectId: '$subjectId' }
            }
        }
    ]);

    const ops = [];
    for (const pair of pairs) {
        const examId = pair._id.examId;
        const subjectId = pair._id.subjectId;
        if (!examId || !subjectId) {
            continue;
        }

        const legacy = await Subject.findOne({ id: subjectId }).lean();
        ops.push({
            updateOne: {
                filter: { examId, id: subjectId },
                update: {
                    $setOnInsert: {
                        examId,
                        id: subjectId,
                        name: legacy?.name || subjectId
                    }
                },
                upsert: true
            }
        });
    }

    if (ops.length) {
        await Subject.bulkWrite(ops);
    }

    console.log(`Backfill complete. Upserted subject pairs: ${ops.length}`);
    process.exit(0);
}

run().catch((err) => {
    console.error('Backfill failed', err);
    process.exit(1);
});
