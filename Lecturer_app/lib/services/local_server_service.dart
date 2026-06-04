import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../services/qr_token_service.dart';
import '../database/database_helper.dart';

class LocalServerService {
  HttpServer? _server;

  Future<void> startServer() async {
    final router = Router();
    final studentService = StudentService();
    final attendanceService = AttendanceService();
    final qrTokenService = QrTokenService();

    router.get('/api/ping', (Request request) {
      return Response.ok(
        jsonEncode({"status": "success", "message": "Server Running"}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.post('/api/student/login', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      // Bersihkan NIM sebagai String
      final nim = data['nim'].toString().trim();
      
      print("Mencoba login dengan NIM: '$nim'");

      final student = await studentService.validateNim(nim);

      if (student == null) {
        print("Error: NIM '$nim' tidak ditemukan.");
        return Response(
          404,
          body: jsonEncode({"status": "error", "message": "Student not found"}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = await DatabaseHelper.instance.database;
      
      // Kueri dengan record_id yang sesuai dengan database_helper.dart
      final coursesResult = await db.rawQuery('''
        SELECT 
          c.course_name,
          COALESCE(
            (SELECT 
              CASE 
                WHEN COUNT(s.session_id) = 0 THEN 0 
                ELSE (CAST(COUNT(a.record_id) AS FLOAT) * 100 / COUNT(s.session_id))
              END
             FROM sessions s
             LEFT JOIN attendance_records a ON a.session_id = s.session_id AND a.nim = ?
             WHERE s.course_id = c.course_id
            ), 0) as attendance_percent
        FROM student_courses sc
        JOIN courses c ON sc.course_id = c.course_id
        WHERE sc.student_nim = ?
      ''', [nim, nim]);

      final formattedCourses = coursesResult.map((c) {
        return {
          "course_name": c['course_name'],
          "attendance_percent": (c['attendance_percent'] as num? ?? 0).round(),
        };
      }).toList();

      return Response.ok(
        jsonEncode({
          "status": "success",
          "data": {
            "nim": student.nim,
            "nama": student.nama,
            "courses": formattedCourses,
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.post('/api/attendance/scan', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final nim = data['nim'].toString().trim();
      final tokenQr = data['token_qr'];

      final sessionId = await qrTokenService.getSessionIdByToken(tokenQr);

      if (sessionId == null) {
        return Response(404, body: jsonEncode({"status": "error", "message": "Invalid QR Token"}));
      }

      final result = await attendanceService.saveAttendance(
        nim: nim,
        sessionId: sessionId,
      );

      if (result == "Attendance recorded") {
        return Response.ok(jsonEncode({"status": "success", "message": result}));
      }

      return Response(400, body: jsonEncode({"status": "error", "message": result}));
    });

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 5001);
    print("SERVER RUNNING ON PORT 5001");
  }

  Future<void> stopServer() async {
    await _server?.close();
  }
}