import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/student_model.dart';

class StudentService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Student?> validateNim(String nim) async {
    final Database db = await _dbHelper.database;

    final result = await db.query(
      'students',
      where: 'nim = ?',
      whereArgs: [nim],
    );

    if (result.isEmpty) {
      return null;
    }

    return Student.fromMap(result.first);
  }

  Future<List<Student>> getAllStudents() async {
    final Database db = await _dbHelper.database;

    final result = await db.query('students');

    return result.map((e) => Student.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> getStudentStatistics(String nim) async {
    final db = await _dbHelper.database;

    final attendanceResult = await db.rawQuery(
      '''
    SELECT COUNT(*) as total
    FROM attendance_records
    WHERE nim = ?
    ''',
      [nim],
    );

    final sessionResult = await db.rawQuery('''
    SELECT COUNT(*) as total
    FROM sessions
    ''');

    final totalPresent = attendanceResult.first['total'] as int;

    final totalSessions = sessionResult.first['total'] as int;

    final percentage = totalSessions == 0
        ? 0.0
        : (totalPresent / totalSessions) * 100;

    return {
      'present': totalPresent,

      'sessions': totalSessions,

      'percentage': percentage,
    };
  }
}
