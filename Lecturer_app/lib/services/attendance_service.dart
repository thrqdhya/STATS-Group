import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';

class AttendanceService {
  final DatabaseHelper _dbHelper =
      DatabaseHelper.instance;

  // ==========================================
  // CEK APAKAH MAHASISWA SUDAH ABSEN
  // ==========================================

  Future<bool> hasAttendance(
    String nim,
    int sessionId,
  ) async {
    final Database db =
        await _dbHelper.database;

    final result = await db.query(
      'attendance_records',
      where:
          'nim = ? AND session_id = ?',
      whereArgs: [
        nim,
        sessionId,
      ],
    );

    return result.isNotEmpty;
  }

  // ==========================================
  // CEK SESSION MASIH AKTIF
  // ==========================================

  Future<bool> isSessionActive(
    int sessionId,
  ) async {
    final Database db =
        await _dbHelper.database;

    final result = await db.query(
      'sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    if (result.isEmpty) {
      return false;
    }

    final session =
        SessionModel.fromMap(
      result.first,
    );

    return session.isActive();
  }

  // ==========================================
  // SIMPAN ABSENSI
  // ==========================================

  Future<String> saveAttendance({
    required String nim,
    required int sessionId,
  }) async {
    final Database db =
        await _dbHelper.database;

    // cek session aktif

    final active =
        await isSessionActive(
      sessionId,
    );

    if (!active) {
      return "Session expired";
    }

    // cek double attendance

    final already =
        await hasAttendance(
      nim,
      sessionId,
    );

    if (already) {
      return "Attendance already recorded";
    }

    // simpan attendance

    await db.insert(
      'attendance_records',
      {
        'nim': nim,
        'session_id': sessionId,
        'status': 'PRESENT',
        'timestamp':
            DateTime.now()
                .toIso8601String(),
      },
    );

    return "Attendance recorded";
  }

  Future<int> getAttendanceCount(
  int sessionId,
) async {

  final Database db =
      await _dbHelper.database;

  final result =
      await db.rawQuery(
    '''
    SELECT COUNT(*) as total
    FROM attendance_records
    WHERE session_id = ?
    ''',
    [sessionId],
  );

  return result.first['total']
      as int;
}

Future<List<Map<String, dynamic>>>
getRecentScans(
  int sessionId,
) async {

  final Database db =
      await _dbHelper.database;

  final result =
      await db.rawQuery(
    '''
    SELECT
      students.nama,
      attendance_records.timestamp
    FROM attendance_records

    INNER JOIN students
    ON students.nim =
       attendance_records.nim

    WHERE attendance_records.session_id = ?

    ORDER BY attendance_records.timestamp DESC

    LIMIT 10
    ''',
    [sessionId],
  );

  return result;
}
}