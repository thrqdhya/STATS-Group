import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class QrTokenService {

  final DatabaseHelper _dbHelper =
      DatabaseHelper.instance;

  Future<void> saveToken({
    required String token,
    required int sessionId,
    required DateTime expiresAt,
  }) async {

    final Database db =
        await _dbHelper.database;

    await db.insert(
      'qr_tokens',
      {
        'token': token,
        'created_at':
            DateTime.now()
                .toIso8601String(),

        'expires_at':
            expiresAt
                .toIso8601String(),

        'session_id':
            sessionId,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<int?> getSessionIdByToken(
    String token,
  ) async {

    final Database db =
        await _dbHelper.database;

    final result =
        await db.query(
      'qr_tokens',
      where: 'token = ?',
      whereArgs: [token],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first[
        'session_id'] as int;
  }
}