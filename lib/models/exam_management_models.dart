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
  final String name;
  // Optionally add other fields like qualification, exam_level later

  Exam({required this.id, required this.sectorId, required this.name});

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      sectorId: map['sector_id'],
      name: map['exam_name'], // DB column is exam_name
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'sector_id': sectorId, 'exam_name': name};
  }
}
