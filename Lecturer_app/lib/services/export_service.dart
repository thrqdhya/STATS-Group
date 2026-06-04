import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> exportAttendance(int sessionId) async {
    final Database db = await _dbHelper.database;

    // 1. Fetch Session and Course Info (Using LEFT JOIN to ensure date is always fetched)
    final sessionResult = await db.rawQuery('''
      SELECT s.tanggal, c.course_name 
      FROM sessions s
      LEFT JOIN courses c ON s.course_id = c.course_id
      WHERE s.session_id = ?
    ''', [sessionId]);

    String courseName = "Course";
    String date = "Date";
    
    if (sessionResult.isNotEmpty) {
      final dbCourseName = sessionResult.first['course_name'];
      final dbDate = sessionResult.first['tanggal'];

      if (dbCourseName != null) {
        courseName = dbCourseName.toString().replaceAll(' ', '_');
      }
      if (dbDate != null) {
        // Mengambil 10 karakter pertama saja (YYYY-MM-DD), lalu dibalik menjadi DD-MM-YYYY
        String rawDate = dbDate.toString().substring(0, 10); // Hasil: 2026-06-04
        List<String> parts = rawDate.split('-');
        date = "${parts[2]}-${parts[1]}-${parts[0]}"; // Hasil akhir: 04-06-2026
      }
    }

    // 2. Fetch Attendance Data (Using LEFT JOIN for unregistered students)
    final result = await db.rawQuery(
      '''
      SELECT
        attendance_records.nim,
        COALESCE(students.nama, 'Unregistered Student') as nama,
        attendance_records.status,
        attendance_records.timestamp
      FROM attendance_records
      LEFT JOIN students ON students.nim = attendance_records.nim
      WHERE attendance_records.session_id = ?
      ''',
      [sessionId],
    );

    // Mencegah pembuatan file jika tidak ada yang absen
    if (result.isEmpty) {
      return "Failed: No attendance data for this session.";
    }

    // 3. Create Excel Document
    final excel = Excel.createExcel();
    
    // Mengubah nama Sheet bawaan menjadi bahasa Inggris
    excel.rename('Sheet1', 'Attendance');
    final sheet = excel['Attendance'];

    // Excel Headers in English
    sheet.appendRow([
      TextCellValue("Student_ID"),
      TextCellValue("Student_Name"),
      TextCellValue("Status"),
      TextCellValue("Timestamp"),
    ]);

    // Input data to rows
    for (final row in result) {
      sheet.appendRow([
        TextCellValue(row['nim'].toString()),
        TextCellValue(row['nama'].toString()),
        TextCellValue(row['status'].toString()),
        TextCellValue(row['timestamp'].toString()),
      ]);
    }

    // 4. Save the file with Dynamic English Name
    final dir = await getApplicationDocumentsDirectory();
    
    // NAMA FILE BARU: Contoh "Attendance_Mobil_Uygulama_2026-06-04.xlsx"
    final fileName = "Attendance_${courseName}_$date.xlsx";
    final filePath = "${dir.path}/$fileName";

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return filePath;
  }
}