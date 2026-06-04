import 'package:flutter/material.dart';
import '../services/lecturer_service.dart';
import 'lecturer_dashboard_page.dart';

class LecturerLoginPage extends StatefulWidget {
  const LecturerLoginPage({super.key});

  @override
  State<LecturerLoginPage> createState() =>
      _LecturerLoginPageState();
}

class _LecturerLoginPageState
    extends State<LecturerLoginPage> {
  
  final LecturerService lecturerService =
    LecturerService();

  bool isLoading = false;

  final usernameController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {

  final username =
      usernameController.text.trim();

  final password =
      passwordController.text.trim();

  if (username.isEmpty ||
      password.isEmpty) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text("Fill all fields"),
      ),
    );

    return;
  }

  setState(() {
    isLoading = true;
  });

  final lecturer =
      await lecturerService.login(
    username,
    password,
  );

  setState(() {
    isLoading = false;
  });

  if (lecturer == null) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text("Invalid Login"),
      ),
    );

    return;
  }

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => LecturerDashboardPage(
        lecturerName: lecturer.nama,
        // TAMBAHAN BARU: Mengirimkan ID dosen dari hasil login ke Dashboard
        lecturerId: lecturer.lecturerId!, 
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0b1a58),

      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF3b82f6),

                child: Icon(
                  Icons.school,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Teacher Login",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: usernameController,

                decoration: InputDecoration(
                  labelText: "Username",

                  prefixIcon:
                      const Icon(Icons.person),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,

                decoration: InputDecoration(
                  labelText: "Password",

                  prefixIcon:
                      const Icon(Icons.lock),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : login,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF3b82f6),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}