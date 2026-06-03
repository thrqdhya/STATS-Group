import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/lecturer_model.dart';

class LecturerService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Lecturer?> login(
    String username,
    String password,
  ) async {
    final Database db = await _dbHelper.database;

    final result = await db.query(
      'lecturers',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isEmpty) {
      return null;
    }

    return Lecturer.fromMap(result.first);
  }
}