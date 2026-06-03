import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/session_model.dart';

class SessionService {
  final DatabaseHelper _dbHelper =
      DatabaseHelper.instance;

  Future<SessionModel> createSession({
    required int lecturerId,
    int? courseId,
  }) async {

    final db = await _dbHelper.database;

    final now = DateTime.now();

    final expiresAt =
        now.add(
      const Duration(
        minutes: 5,
      ),
    );

    final id = await db.insert(
      'sessions',
      {
        'tanggal':
            now.toIso8601String(),

        'expires_at':
            expiresAt.toIso8601String(),

        'lecturer_id':
            lecturerId,

        'course_id':
            courseId,
      },
    );

    return SessionModel(
      sessionId: id,
      tanggal: now,
      expiresAt: expiresAt,
      lecturerId: lecturerId,
      courseId: courseId,
    );
  }

  Future<SessionModel?> getLatestSession()
  async {

    final db =
        await _dbHelper.database;

    final result =
        await db.query(
      'sessions',
      orderBy:
          'session_id DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return SessionModel.fromMap(
      result.first,
    );
  }
}