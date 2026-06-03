import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../models/session_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/token_service.dart';
import 'dart:async';
import '../services/attendance_service.dart';
import '../services/export_service.dart';
import '../services/qr_token_service.dart';

class LecturerDashboardPage extends StatefulWidget {
  final String lecturerName;

  const LecturerDashboardPage({super.key, required this.lecturerName});

  @override
  State<LecturerDashboardPage> createState() => _LecturerDashboardPageState();
}

class _LecturerDashboardPageState extends State<LecturerDashboardPage> {
  Timer? countdownTimer;

  int remainingSeconds = 300;

  final AttendanceService attendanceService = AttendanceService();

  final TokenService tokenService = TokenService();

  final QrTokenService qrTokenService = QrTokenService();

  String? currentToken;

  final SessionService sessionService = SessionService();

  final ExportService exportService = ExportService();

  SessionModel? currentSession;
  int attendanceCount = 0;
  List<Map<String, dynamic>> recentScans = [];

  Timer? qrRefreshTimer;
  Timer? liveRefreshTimer;

  String selectedCourse = "Gorsel Programlama";

  Future<void> startSession() async {
    final session = await sessionService.createSession(lecturerId: 1);

    final token = tokenService.generateToken();

    await qrTokenService.saveToken(
      token: token,

      sessionId: session.sessionId!,

      expiresAt: session.expiresAt,
    );

    setState(() {
      currentSession = session;

      currentToken = token;
    });

    startCountdown();

    startQrRefresh();

    startLiveRefresh();

    attendanceCount = 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Session #${session.sessionId} Created")),
    );
  }

  Future<void> testAttendance() async {
    if (currentSession == null) {
      return;
    }

    final result = await attendanceService.saveAttendance(
      nim: "23670708027",
      sessionId: currentSession!.sessionId!,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));

    await refreshAttendanceCount();

    await refreshRecentScans();
  }

  Future<void> refreshAttendanceCount() async {
    if (currentSession == null) {
      return;
    }

    final count = await attendanceService.getAttendanceCount(
      currentSession!.sessionId!,
    );

    setState(() {
      attendanceCount = count;
    });
  }

  Future<void> refreshRecentScans() async {
    if (currentSession == null) {
      return;
    }

    final scans = await attendanceService.getRecentScans(
      currentSession!.sessionId!,
    );

    setState(() {
      recentScans = scans;
    });
  }

  void startLiveRefresh() {
    liveRefreshTimer?.cancel();

    liveRefreshTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (currentSession == null) {
        return;
      }

      await refreshAttendanceCount();

      await refreshRecentScans();
    });
  }

  Future<void> exportExcel() async {
    if (currentSession == null) {
      return;
    }

    final filePath = await exportService.exportAttendance(
      currentSession!.sessionId!,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Excel Saved:\n$filePath")));
  }

  void startCountdown() {
    countdownTimer?.cancel();

    remainingSeconds = 300;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds <= 0) {
        timer.cancel();

        qrRefreshTimer?.cancel();

        liveRefreshTimer?.cancel();

        setState(() {
          currentSession = null;
          currentToken = null;
        });

        await exportExcel();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Session Ended"),

              content: const Text(
                "Attendance session has expired.\nPlease create a new session.",
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }

        return;
      }

      setState(() {
        remainingSeconds--;
      });
    });
  }

  void startQrRefresh() {
    qrRefreshTimer?.cancel();

    qrRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (currentSession == null) {
        timer.cancel();
        return;
      }

      final token = tokenService.generateToken();

      await qrTokenService.saveToken(
        token: token,

        sessionId: currentSession!.sessionId!,

        expiresAt: currentSession!.expiresAt,
      );

      setState(() {
        currentToken = token;
      });
    });
  }

  String get timerText {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');

    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    countdownTimer?.cancel();

    qrRefreshTimer?.cancel();

    liveRefreshTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 280,
            color: const Color(0xFF0F172A),

            child: Column(
              children: [
                const SizedBox(height: 50),

                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    widget.lecturerName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Welcome Back",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.lecturerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.all(20),

                  child: DropdownButtonFormField<String>(
                    value: selectedCourse,

                    dropdownColor: Colors.white,

                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                    ),

                    items: const [
                      DropdownMenuItem(
                        value: "Gorsel Programlama",
                        child: Text("Gorsel Programlama"),
                      ),
                    ],

                    onChanged: (value) {
                      setState(() {
                        selectedCourse = value!;
                      });
                    },
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(20),

                  child: SizedBox(
                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton(
                      onPressed: startSession,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),

                      child: const Text("START SESSION"),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 40),

                const Text(
                  "Session Dashboard",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                Container(
                  width: 400,
                  height: 400,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Center(
                    child: currentToken == null
                        ? const Text("NO ACTIVE SESSION")
                        : QrImageView(data: currentToken!, size: 250),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  currentSession == null ? "NO SESSION" : timerText,

                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // RIGHT PANEL
          Container(
            width: 300,
            color: Colors.white,

            child: Column(
              children: [
                const SizedBox(height: 50),

                const Text(
                  "Students Present",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Text(
                  attendanceCount.toString(),

                  style: const TextStyle(
                    fontSize: 64,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "Recent Scans",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    itemCount: recentScans.length,

                    itemBuilder: (context, index) {
                      final scan = recentScans[index];

                      return ListTile(
                        leading: const Icon(Icons.person),

                        title: Text(scan['nama'].toString()),

                        subtitle: Text(scan['timestamp'].toString()),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: exportExcel,

                  child: const Text("EXPORT EXCEL"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
