// lib/screens/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'scanner_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const DashboardPage({super.key, required this.studentData});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> currentData;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    currentData = widget.studentData;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  Future<void> _refreshData() async {
    final nim = currentData['nim'];
    if (nim == null) return;

    try {
      final url = Uri.parse("$baseUrl/api/student/login");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nim": nim}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          currentData = result['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Courses updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to refresh data"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = currentData['nama'] ?? 'Student';
    final String nim = currentData['nim'] ?? '';
    final List courses = currentData['courses'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b1a58),
        foregroundColor: Colors.white,
        title: const Text("Student Dashboard"),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _showLogoutDialog),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 5))],
                border: const Border(left: BorderSide(color: Color(0xFF3b82f6), width: 5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(name.isNotEmpty ? name[0] : 'S', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text("NIM: $nim", style: const TextStyle(color: Color(0xFF3b82f6), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Enrolled Class", "${courses.length}", Icons.menu_book_rounded, Colors.blue.shade600),
                _buildStatCard("Status Account", "Active", Icons.verified_user_rounded, Colors.teal.shade600),
              ],
            ),
            const SizedBox(height: 25),
            const Text("My Enrolled Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 15),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: const Color(0xFF3b82f6),
                child: courses.isEmpty
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [Padding(padding: EdgeInsets.only(top: 50.0), child: Center(child: Text("No courses found for this student.")))])
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          final int percent = course['attendance_percent'] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.book, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(course['course_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                    ),
                                    Text("$percent%", style: TextStyle(fontWeight: FontWeight.bold, color: percent < 75 ? Colors.red : Colors.green)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: percent / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(percent < 75 ? Colors.redAccent : Colors.green),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 15),
            ScaleTransition(
              scale: _pulseAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Logic untuk menangkap signal refresh dari scanner
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScannerPage(studentNim: nim)),
                    );

                    if (result == true) {
                      _refreshData();
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text("SCAN FOR ATTENDANCE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 6,
                    shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}