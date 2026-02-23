import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/history_model.dart';
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'auth_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Completer<Database>? _dbCompleter;

  Future<Database> get database async {
    if (_dbCompleter != null) return _dbCompleter!.future;

    _dbCompleter = Completer<Database>();

    try {
      if (_database != null) {
        _dbCompleter!.complete(_database);
        return _database!;
      }

      _database = await _initDB('quiz_history.db');
      _dbCompleter!.complete(_database);
      return _database!;
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null; // Reset to allow retry
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    if (kDebugMode) {
      print('Initializing database at $path');
    }

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Quiz History Table
    await db.execute('''
      CREATE TABLE quiz_results (
        id TEXT PRIMARY KEY,
        userId TEXT,
        topic $textType,
        examName $textType,
        subject $textType,
        score $integerType,
        totalQuestions $integerType,
        date $textType,
        quizDataJson $textType
      )
    ''');

    // User Profile Table (For Credits/Economy)
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        credits INTEGER DEFAULT 100,
        last_daily_bonus TEXT
      )
    ''');

    // Credit History Table
    await db.execute('''
      CREATE TABLE credit_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER,
        type TEXT,
        description TEXT,
        date TEXT
      )
    ''');

    // Initialize default profile
    await db.insert('user_profile', {
      'id': 'default_user',
      'credits': 100,
      'last_daily_bonus': DateTime.now().toIso8601String(),
    });

    if (kDebugMode) {
      print('Database tables created.');
    }
  }

  Future<int> insertResult(QuizResult result) async {
    final db = await instance.database;

    // Proactively sync to Supabase if possible
    _syncResultToSupabase(result).catchError((e) {
      if (kDebugMode) print("Non-blocking Supabase sync error: $e");
    });

    return await db.insert('quiz_results', result.toMap());
  }

  Future<void> _syncResultToSupabase(QuizResult result) async {
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        await Supabase.instance.client.from('quiz_results').insert({
          'user_id': userId,
          'topic': result.topic,
          'subject': result.subject,
          'exam_name': result.examName,
          'score': result.score,
          'total_questions': result.totalQuestions,
          'quiz_data_json': result.quizDataJson,
          'created_at': result.date.toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) print("Supabase sync failed for result: $e");
    }
  }

  Future<List<QuizResult>> getAllResults({String? userId}) async {
    final db = await instance.database;
    final orderBy = 'date DESC';

    // Filter by userId if provided to ensure data isolation
    final List<Map<String, dynamic>> result = userId != null
        ? await db.query(
            'quiz_results',
            where: 'userId = ?',
            whereArgs: [userId],
            orderBy: orderBy,
          )
        : await db.query('quiz_results', orderBy: orderBy);

    return result.map((json) => QuizResult.fromMap(json)).toList();
  }

  /// Get current user credits
  Future<int> getCredits() async {
    // 1. Try Supabase if logged in
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        final response = await Supabase.instance.client
            .from('profiles')
            .select('credits')
            .eq('id', userId!)
            .maybeSingle();

        if (response != null) {
          return response['credits'] as int;
        }
      }
    } catch (e) {
      if (kDebugMode) print("Supabase fetch error: $e");
    }

    // 2. Fallback to Local DB
    final db = await instance.database;
    final result = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: ['default_user'],
    );

    if (result.isNotEmpty) {
      return result.first['credits'] as int;
    } else {
      return 100; // Fallback
    }
  }

  /// Update user credits (absolute value)
  Future<int> updateCredits(int newBalance) async {
    // 1. Update Supabase if logged in
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        await Supabase.instance.client
            .from('profiles')
            .update({'credits': newBalance})
            .eq('id', userId!);
      }
    } catch (e) {
      if (kDebugMode) print("Supabase update error: $e");
    }

    // 2. Always update Local DB (for offline sync later)
    final db = await instance.database;
    return await db.update(
      'user_profile',
      {'credits': newBalance},
      where: 'id = ?',
      whereArgs: ['default_user'],
    );
  }

  /// Get last bonus date
  Future<String?> getLastBonusDate() async {
    // 1. Try Supabase if logged in
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        final response = await Supabase.instance.client
            .from('profiles')
            .select('last_daily_bonus')
            .eq('id', userId!)
            .maybeSingle();

        if (response != null) {
          return response['last_daily_bonus'] as String?;
        }
      }
    } catch (e) {
      if (kDebugMode) print("Supabase bonus fetch error: $e");
    }

    // 2. Fallback to Local DB
    final db = await instance.database;
    final result = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: ['default_user'],
    );

    if (result.isNotEmpty) {
      return result.first['last_daily_bonus'] as String?;
    }
    return null;
  }

  /// Update last bonus date
  Future<void> updateBonusDate(String date) async {
    // 1. Update Supabase if logged in
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        await Supabase.instance.client
            .from('profiles')
            .update({'last_daily_bonus': date})
            .eq('id', userId!);
      }
    } catch (e) {
      if (kDebugMode) print("Supabase bonus update error: $e");
    }

    // 2. Always update Local DB
    final db = await instance.database;
    await db.update(
      'user_profile',
      {'last_daily_bonus': date},
      where: 'id = ?',
      whereArgs: ['default_user'],
    );
  }

  Future<int> deleteResult(String id) async {
    final db = await instance.database;
    return await db.delete('quiz_results', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllResults() async {
    // 1. Clear Supabase if logged in
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        await Supabase.instance.client
            .from('quiz_results')
            .delete()
            .eq('user_id', userId!);
      }
    } catch (e) {
      if (kDebugMode) print("Supabase clear error: $e");
    }

    // 2. Clear Local DB
    final db = await instance.database;
    await db.delete('quiz_results');
  }

  /// Update User Progress for a specific exam in Supabase
  Future<void> updateExamProgress(
    String examName,
    int progressIncrement,
  ) async {
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;

        // Find Exam ID
        final examRes = await Supabase.instance.client
            .from('exams')
            .select('id')
            .eq('exam_name', examName)
            .maybeSingle();

        if (examRes != null) {
          final examId = examRes['id'];

          // 1. Fetch current progress
          final currentProgressRes = await Supabase.instance.client
              .from('user_progress')
              .select('progress')
              .eq('user_id', userId!)
              .eq('exam_id', examId)
              .maybeSingle();

          int currentProgress = (currentProgressRes?['progress'] ?? 0);
          int newProgress = currentProgress + progressIncrement;

          // 2. Upsert progress
          await Supabase.instance.client.from('user_progress').upsert({
            'user_id': userId,
            'exam_id': examId,
            'progress': newProgress,
            'last_study': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,exam_id');
        }
      }
    } catch (e) {
      if (kDebugMode) print("Progress update failed: $e");
    }
  }

  // --- Credit History Methods ---

  Future<int> addCreditTransaction(
    int amount,
    String type,
    String description,
  ) async {
    // 1. Supabase
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        await Supabase.instance.client.from('credit_transactions').insert({
          'user_id': userId,
          'amount': amount,
          'type': type,
          'description': description,
          // 'created_at': DateTime.now().toIso8601String() // handled by default
        });
      }
    } catch (e) {
      if (kDebugMode) print("Supabase tx error: $e");
    }

    // 2. Local DB
    final db = await instance.database;
    return await db.insert('credit_history', {
      'amount': amount,
      'type': type,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCreditHistory() async {
    // 1. Supabase
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn) {
        final userId = auth.userId;
        final response = await Supabase.instance.client
            .from('credit_transactions')
            .select()
            .eq('user_id', userId!)
            .order('created_at', ascending: false);

        // Map Supabase 'created_at' to local 'date' format if needed, or UI handles it
        return List<Map<String, dynamic>>.from(response).map((e) {
          return {
            ...e,
            'date': e['created_at'], // Map for UI compatibility
          };
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) print("Supabase history error: $e");
    }

    // 2. Local DB Fallback
    final db = await instance.database;
    return await db.query('credit_history', orderBy: 'date DESC');
  }

  // Handle schema migrations
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE user_profile (
          id TEXT PRIMARY KEY,
          credits INTEGER DEFAULT 100,
          last_daily_bonus TEXT
        )
      ''');

      // Initialize default profile
      await db.insert('user_profile', {
        'id': 'default_user',
        'credits': 100,
        'last_daily_bonus': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      });
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE credit_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount INTEGER,
          type TEXT,
          description TEXT,
          date TEXT
        )
      ''');

      // Ensure quiz_results has 'id' and 'userId' columns for existing users
      try {
        await db.execute('ALTER TABLE quiz_results ADD COLUMN id TEXT');
      } catch (e) {
        if (kDebugMode)
          print("Migration: id column already exists or table missing.");
      }
      try {
        await db.execute('ALTER TABLE quiz_results ADD COLUMN userId TEXT');
      } catch (e) {
        if (kDebugMode) print("Migration v3: userId column already exists.");
      }
    }

    if (oldVersion < 6) {
      // Version 6: Robust recreation of quiz_results to fix ANY lingering id/type issues
      try {
        await db.transaction((txn) async {
          // 1. Drop old backup if exists
          await txn.execute('DROP TABLE IF EXISTS quiz_results_old');

          // 2. Rename existing table
          try {
            await txn.execute(
              'ALTER TABLE quiz_results RENAME TO quiz_results_old',
            );
          } catch (_) {
            // Table might not exist, skip rename
          }

          // 3. Create fresh table with confirmed PRIMARY KEY TEXT
          await txn.execute('''
            CREATE TABLE quiz_results (
              id TEXT PRIMARY KEY,
              userId TEXT,
              topic TEXT NOT NULL,
              examName TEXT NOT NULL,
              subject TEXT NOT NULL,
              score INTEGER NOT NULL,
              totalQuestions INTEGER NOT NULL,
              date TEXT NOT NULL,
              quizDataJson TEXT NOT NULL
            )
          ''');

          // 4. Migrate data if possible
          try {
            await txn.execute('''
              INSERT INTO quiz_results (id, userId, topic, examName, subject, score, totalQuestions, date, quizDataJson)
              SELECT 
                CAST(id AS TEXT), 
                CAST(userId AS TEXT), 
                topic, examName, subject, score, totalQuestions, date, quizDataJson
              FROM quiz_results_old
            ''');
          } catch (_) {
            if (kDebugMode)
              print("Note: Data migration skipped during v6 recreation.");
          }

          // 5. Drop old table
          try {
            await txn.execute('DROP TABLE quiz_results_old');
          } catch (_) {}
        });
        if (kDebugMode) print("Migration v6: Re-verified quiz_results schema.");
      } catch (e) {
        if (kDebugMode) print("Migration v6 error: $e");
      }
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
