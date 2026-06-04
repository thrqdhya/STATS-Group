import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/student_model.dart';

class StudentService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Student?> validateNim(String nim) async {
    final Database db = await _dbHelper.database;
    
    // 1. Bersihkan input dari spasi yang tidak terlihat
    final cleanNim = nim.trim();
    
    print("DEBUG: Mencari NIM di database: '$cleanNim'");

    // 2. Query dengan penanganan tipe data (try-catch atau casting)
    // Jika NIM di DB adalah Integer, maka cleanNim harus diubah jadi int
    final result = await db.query(
      'students',
      where: 'nim = ?',
      whereArgs: [cleanNim], // Pastikan format ini sesuai dengan format di DB
    );

    if (result.isEmpty) {
      print("DEBUG: Hasil query kosong untuk NIM: '$cleanNim'");
      
      // Coba trik: cek apakah ada data di tabel students sama sekali
      final count = await Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM students'));
      print("DEBUG: Total mahasiswa di database saat ini: $count");
      
      return null;
    }

    print("DEBUG: Mahasiswa berhasil ditemukan: ${result.first['nama']}");
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
      'SELECT COUNT(*) as total FROM attendance_records WHERE nim = ?',
      [nim],
    );

    final sessionResult = await db.rawQuery('SELECT COUNT(*) as total FROM sessions');

    final totalPresent = (attendanceResult.first['total'] as int?) ?? 0;
    final totalSessions = (sessionResult.first['total'] as int?) ?? 0;

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