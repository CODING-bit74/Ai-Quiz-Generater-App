class ExamSector {
  final String id; // UUID
  final String name;
  final String? iconName;

  ExamSector({required this.id, required this.name, this.iconName});

  factory ExamSector.fromMap(Map<String, dynamic> map) {
    return ExamSector(
      id: map['id'],
      name: map['name'],
      iconName: map['icon_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon_name': iconName};
  }
}

class Exam {
  final String id; // UUID
  final String sectorId; // UUID
  final Map<String, dynamic>? examPattern;
  final Map<String, dynamic>? eligibility;
  final String name;

  Exam({
    required this.id,
    required this.sectorId,
    required this.name,
    this.examPattern,
    this.eligibility,
  });

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      sectorId: map['sector_id'],
      name: map['exam_name'],
      examPattern: map['exam_pattern'],
      eligibility: map['eligibility'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sector_id': sectorId,
      'exam_name': name,
      'exam_pattern': examPattern,
      'eligibility': eligibility,
    };
  }
}
