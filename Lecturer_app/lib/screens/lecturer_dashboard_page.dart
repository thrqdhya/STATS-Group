import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../models/session_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/token_service.dart';
import 'dart:async';
import '../services/attendance_service.dart';
import '../services/export_service.dart';
import '../services/qr_token_service.dart';
import '../database/database_helper.dart'; 
import 'lecturer_login_page.dart'; // TAMBAHAN: Untuk fungsi Logout

class LecturerDashboardPage extends StatefulWidget {
  final String lecturerName;
  final int lecturerId;

  const LecturerDashboardPage({
    super.key, 
    required this.lecturerName,
    required this.lecturerId,
  });

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

  // Variabel untuk Dropdown & Total Mahasiswa
  int? selectedCourseId;
  List<Map<String, dynamic>> availableCourses = [];
  int totalEnrolledStudents = 0; 

  // Variabel untuk Jam Real-time
  Timer? clockTimer;
  String currentTime = "";

  // Variabel untuk Input Absen Manual
  final TextEditingController manualNimController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _startClock(); // Mulai jam digital
  }

  // 1. FUNGSI JAM DIGITAL
  void _startClock() {
    clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final d = now.day.toString().padLeft(2, '0');
      final m = now.month.toString().padLeft(2, '0');
      final y = now.year.toString();
      final h = now.hour.toString().padLeft(2, '0');
      final min = now.minute.toString().padLeft(2, '0');
      final s = now.second.toString().padLeft(2, '0');
      
      if (mounted) {
        setState(() {
          currentTime = "$d/$m/$y   $h:$min:$s";
        });
      }
    });
  }

  // 2. FUNGSI MENGAMBIL TOTAL MAHASISWA
  Future<void> _fetchTotalStudents(int courseId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'student_courses', 
      where: 'course_id = ?', 
      whereArgs: [courseId]
    );
    setState(() {
      totalEnrolledStudents = result.length;
    });
  }

  Future<void> _loadCourses() async {
    final db = await DatabaseHelper.instance.database;
    final courses = await db.query(
      'courses',
      where: 'lecturer_id = ?',
      whereArgs: [widget.lecturerId], 
    ); 
    
    setState(() {
      availableCourses = courses;
      if (availableCourses.isNotEmpty) {
        selectedCourseId = availableCourses.first['course_id'] as int;
        _fetchTotalStudents(selectedCourseId!); // Hitung mahasiswa saat pertama kali buka
      } else {
        selectedCourseId = null;
      }
    });
  }

  Future<void> startSession() async {
    if (selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Warning: Please select a course first!"), 
          backgroundColor: Colors.orange
        ),
      );
      return;
    }

    final session = await sessionService.createSession(
      lecturerId: widget.lecturerId,
      courseId: selectedCourseId!, 
    );

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

  Future<void> stopSession() async {
    countdownTimer?.cancel();
    qrRefreshTimer?.cancel();
    liveRefreshTimer?.cancel();

    setState(() {
      currentSession = null;
      currentToken = null;
    });

    await exportExcel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session Stopped & Data Exported!")),
      );
    }
  }

  // 3. FUNGSI INPUT ABSEN MANUAL (DENGAN VALIDASI KETAT)
  Future<void> addManualAttendance() async {
    if (currentSession == null) return;
    
    final nim = manualNimController.text.trim();
    if (nim.isEmpty) return;

    if (attendanceCount >= totalEnrolledStudents) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Warning: Attendance is already full!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; 
    }

    final db = await DatabaseHelper.instance.database;

    final isEnrolled = await db.query(
      'student_courses',
      where: 'student_nim = ? AND course_id = ?',
      whereArgs: [nim, selectedCourseId],
    );

    if (isEnrolled.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Warning: Student ID is not registered in this course!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return; 
    }

    final isAlreadyPresent = await db.query(
      'attendance_records',
      where: 'nim = ? AND session_id = ?',
      whereArgs: [nim, currentSession!.sessionId],
    );

    if (isAlreadyPresent.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Warning: Student is already marked present!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return; 
    }

    await attendanceService.saveAttendance(
      nim: nim,
      sessionId: currentSession!.sessionId!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Success: Attendance recorded successfully."),
          backgroundColor: Colors.green,
        )
      );
    }

    manualNimController.clear(); 
    await refreshAttendanceCount();
    await refreshRecentScans();
  }

  // 4. FUNGSI LOGOUT
  void logout() {
    countdownTimer?.cancel();
    qrRefreshTimer?.cancel();
    liveRefreshTimer?.cancel();
    clockTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LecturerLoginPage()),
    );
  }

  // --- FUNGSI POP-UP KONFIRMASI ---
  Future<void> _confirmAction({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(content, style: const TextStyle(fontSize: 16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Batal
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Lanjut
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Yes, I'm sure", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      onConfirm(); // Eksekusi fungsi jika dosen menekan "Yes"
    }
  }

  Future<void> refreshAttendanceCount() async {
    if (currentSession == null) return;
    final count = await attendanceService.getAttendanceCount(currentSession!.sessionId!);
    setState(() {
      attendanceCount = count;
    });
  }

  Future<void> refreshRecentScans() async {
    if (currentSession == null) return;
    final scans = await attendanceService.getRecentScans(currentSession!.sessionId!);
    setState(() {
      recentScans = scans;
    });
  }

  void startLiveRefresh() {
    liveRefreshTimer?.cancel();
    liveRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (currentSession == null) return;
      await refreshAttendanceCount();
      await refreshRecentScans();
    });
  }

  Future<void> exportExcel() async {
    if (currentSession == null) return;
    final filePath = await exportService.exportAttendance(currentSession!.sessionId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Excel Saved:\n$filePath")));
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
              content: const Text("Attendance session has expired.\nPlease create a new session."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
    clockTimer?.cancel();
    manualNimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ================= SIDEBAR KIRI =================
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
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Welcome Back", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  widget.lecturerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                
                // Dropdown Pelajaran (Menggunakan ID)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButtonFormField<int>(
                    value: selectedCourseId,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                    items: availableCourses.map((course) {
                      return DropdownMenuItem<int>(
                        value: course['course_id'] as int,
                        child: Text(course['course_name'].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourseId = value;
                      });
                      if (value != null) _fetchTotalStudents(value); 
                    },
                    hint: const Text("Memuat kelas..."),
                  ),
                ),
                
                const Spacer(),
                
                // Tombol Logout di Kiri Bawah (DILENGKAPI KONFIRMASI)
                TextButton.icon(
                  onPressed: () => _confirmAction(
                    title: "Logout Account",
                    content: "Are you sure you want to logout from your account?",
                    onConfirm: logout,
                  ),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                // Tombol START/STOP (DILENGKAPI KONFIRMASI)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: currentSession != null 
                          ? () => _confirmAction(
                              title: "Stop Session",
                              content: "Are you sure you want to stop this session? Students will no longer be able to scan the QR code.",
                              onConfirm: stopSession,
                            ) 
                          : startSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentSession != null ? Colors.red.shade600 : const Color(0xFF2563EB),
                      ),
                      child: Text(
                        currentSession != null ? "STOP SESSION" : "START SESSION",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= TENGAH (CONTENT) =================
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Jam Digital Real-time
                Text(
                  currentTime,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Session Dashboard",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                // Kotak QR Code
                Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ]
                  ),
                  child: Center(
                    child: currentToken == null
                        ? const Text("NO ACTIVE SESSION")
                        : QrImageView(data: currentToken!, size: 250),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Waktu Mundur 5 Menit
                Text(
                  currentSession == null ? "NO SESSION" : timerText,
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),
                
                // Input NIM Manual (Hanya Muncul Saat Sesi Aktif)
                if (currentSession != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: manualNimController,
                          decoration: InputDecoration(
                            hintText: "Manual Input NIM",
                            prefixIcon: const Icon(Icons.edit_document),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: addManualAttendance,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("ADD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    ],
                  ),
              ],
            ),
          ),

          // ================= PANEL KANAN =================
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
                const SizedBox(height: 10),
                
                // Tampilan Total Mahasiswa (Misal: 5 / 40)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      attendanceCount.toString(),
                      style: const TextStyle(fontSize: 64, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      " / $totalEnrolledStudents",
                      style: const TextStyle(fontSize: 24, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text(
                  "Recent Scans",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                // EMPTY STATE & RECENT SCANS
                Expanded(
                  child: recentScans.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              "No scans yet",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Waiting for students...",
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: recentScans.length,
                          itemBuilder: (context, index) {
                            final scan = recentScans[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFEFF6FF),
                                child: Icon(Icons.person, color: Color(0xFF2563EB)),
                              ),
                              title: Text(scan['nama'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(scan['timestamp'].toString()),
                            );
                          },
                        ),
                ),
                
                // Tombol Export Excel Baru
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: exportExcel,
                      icon: const Icon(Icons.file_download, color: Colors.white),
                      label: const Text(
                        "EXPORT EXCEL",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}