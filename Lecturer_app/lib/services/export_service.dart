import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class ExportService {
  final DatabaseHelper _dbHelper =
      DatabaseHelper.instance;

  Future<String> exportAttendance(
    int sessionId,
  ) async {

    final Database db =
        await _dbHelper.database;

    final result =
        await db.rawQuery(
      '''
      SELECT
        students.nim,
        students.nama,
        attendance_records.status,
        attendance_records.timestamp

      FROM attendance_records

      INNER JOIN students

      ON students.nim =
         attendance_records.nim

      WHERE attendance_records.session_id = ?
      ''',
      [sessionId],
    );

    final excel = Excel.createExcel();

    final sheet =
        excel['Attendance'];

    sheet.appendRow([
      TextCellValue("NIM"),
      TextCellValue("Nama"),
      TextCellValue("Status"),
      TextCellValue("Timestamp"),
    ]);

    for (final row in result) {

      sheet.appendRow([
        TextCellValue(
          row['nim'].toString(),
        ),

        TextCellValue(
          row['nama'].toString(),
        ),

        TextCellValue(
          row['status'].toString(),
        ),

        TextCellValue(
          row['timestamp'].toString(),
        ),
      ]);
    }

    final dir =
        await getApplicationDocumentsDirectory();

    final filePath =
        "${dir.path}/attendance_report.xlsx";

    final file =
        File(filePath);

    await file.writeAsBytes(
      excel.encode()!,
    );

    return filePath;
  }
}