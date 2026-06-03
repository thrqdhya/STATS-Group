import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../services/student_service.dart';
import '../services/attendance_service.dart';
import '../services/qr_token_service.dart';

class LocalServerService {
  HttpServer? _server;

  Future<void> startServer() async {
    final router = Router();

    final studentService = StudentService();

    final attendanceService = AttendanceService();

    final qrTokenService = QrTokenService();

    // TEST ENDPOINT

    router.get('/api/ping', (Request request) {
      return Response.ok(
        jsonEncode({"status": "success", "message": "Server Running"}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.post('/api/student/login', (Request request) async {
      final body = await request.readAsString();

      final data = jsonDecode(body);

      final nim = data['nim'];

      final student = await studentService.validateNim(nim);

      if (student == null) {
        return Response(
          404,

          body: jsonEncode({"status": "error", "message": "Student not found"}),

          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          "status": "success",

          "data": {
            "nim": student.nim,

            "nama": student.nama,

            "courses": [
              {"course_name": "Gorsel Programlama"},
            ],
          },
        }),

        headers: {'Content-Type': 'application/json'},
      );
    });

    router.post('/api/attendance/scan', (Request request) async {
      final body = await request.readAsString();

      final data = jsonDecode(body);

      final nim = data['nim'];

      final tokenQr = data['token_qr'];

      final sessionId = await qrTokenService.getSessionIdByToken(tokenQr);

      if (sessionId == null) {
        return Response(
          404,
          body: jsonEncode({"status": "error", "message": "Invalid QR Token"}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await attendanceService.saveAttendance(
        nim: nim,
        sessionId: sessionId,
      );

      if (result == "Attendance recorded") {
        return Response.ok(
          jsonEncode({"status": "success", "message": result}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response(
        400,
        body: jsonEncode({"status": "error", "message": result}),
        headers: {'Content-Type': 'application/json'},
      );
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
