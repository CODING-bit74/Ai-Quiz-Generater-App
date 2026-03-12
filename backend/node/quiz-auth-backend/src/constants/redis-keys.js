// helpers to generate Redis keys for seen bitmaps
function seenKey(userId, examId, subjectId, difficulty) {
    // keep it compact and deterministic
    return `seen:${userId}:${examId}:${subjectId}:${difficulty}`;
}

module.exports = { seenKey };