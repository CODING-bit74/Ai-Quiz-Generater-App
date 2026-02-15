class Organization {
  final String id;
  final String name;
  final String? website;

  Organization({required this.id, required this.name, this.website});

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      website: json['website'],
    );
  }
}

class Post {
  final String id;
  final String examId;
  final String postName;
  final int? salaryMin;
  final int? salaryMax;

  Post({
    required this.id,
    required this.examId,
    required this.postName,
    this.salaryMin,
    this.salaryMax,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      examId: json['exam_id'],
      postName: json['post_name'],
      salaryMin: json['salary_min'],
      salaryMax: json['salary_max'],
    );
  }
}

class Syllabus {
  final String id;
  final String examId;
  final String subject;
  final List<String> topics;

  Syllabus({
    required this.id,
    required this.examId,
    required this.subject,
    required this.topics,
  });

  factory Syllabus.fromJson(Map<String, dynamic> json) {
    return Syllabus(
      id: json['id'],
      examId: json['exam_id'],
      subject: json['subject'],
      topics: List<String>.from(json['topics'] ?? []),
    );
  }
}

class UserProgress {
  final String id;
  final String userId;
  final String examId;
  final int progress;
  final DateTime lastStudy;

  UserProgress({
    required this.id,
    required this.userId,
    required this.examId,
    required this.progress,
    required this.lastStudy,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'],
      userId: json['user_id'],
      examId: json['exam_id'],
      progress: json['progress'] ?? 0,
      lastStudy: DateTime.parse(json['last_study']),
    );
  }
}
