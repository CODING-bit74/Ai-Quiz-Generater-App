import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/history_model.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quiz_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    if (kDebugMode) {
      print('Initializing database at $path');
    }

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE quiz_results (
        id $idType,
        topic $textType,
        examName $textType,
        subject $textType,
        score $integerType,
        totalQuestions $integerType,
        date $textType,
        quizDataJson $textType
      )
    ''');

    if (kDebugMode) {
      print('Database table created.');
    }
  }

  Future<int> insertResult(QuizResult result) async {
    final db = await instance.database;
    return await db.insert('quiz_results', result.toMap());
  }

  Future<List<QuizResult>> getAllResults() async {
    final db = await instance.database;
    final orderBy = 'date DESC';
    final result = await db.query('quiz_results', orderBy: orderBy);

    return result.map((json) => QuizResult.fromMap(json)).toList();
  }

  Future<int> deleteResult(int id) async {
    final db = await instance.database;
    return await db.delete('quiz_results', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
