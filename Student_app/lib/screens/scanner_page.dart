// lib/screens/scanner_page.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/device_service.dart';
import '../constants.dart';

class ScannerPage extends StatefulWidget {
  final String studentNim;

  const ScannerPage({super.key, required this.studentNim});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String scannedData = "Awaiting QR Code...";
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b1a58),
        foregroundColor: Colors.white,
        title: const Text("Scan QR Code", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: MobileScanner(
                  onDetect: (barcodeCapture) {
                    if (isScanned) return;
                    final barcode = barcodeCapture.barcodes.first;
                    final String? code = barcode.rawValue;

                    if (code != null) {
                      setState(() {
                        scannedData = code;
                        isScanned = true;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                children: [
                  Icon(isScanned ? Icons.check_circle : Icons.qr_code_scanner, size: 50, color: isScanned ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(isScanned ? "QR Code Detected!" : "Point camera at the lecturer's screen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isScanned ? const Color(0xFF10B981) : const Color(0xFF334155))),
                  const SizedBox(height: 5),
                  Text(isScanned ? "Ready to submit attendance" : scannedData, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13), textAlign: TextAlign.center),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isScanned
                          ? () async {
                              try {
                                final deviceId = await DeviceService.getDeviceId();
                                final url = Uri.parse("$baseUrl/api/attendance/scan");

                                final response = await http.post(
                                  url,
                                  headers: {"Content-Type": "application/json"},
                                  body: jsonEncode({
                                    "nim": widget.studentNim,
                                    "token_qr": scannedData,
                                    "device_id": deviceId
                                  }),
                                );

                                if (!mounted) return;

                                final result = jsonDecode(response.body);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result["message"] ?? "No message"),
                                    backgroundColor: result["status"] == "success" ? Colors.green : Colors.red,
                                  ),
                                );

                                if (result["status"] == "success") {
                                  // PERUBAHAN DI SINI: Mengirim sinyal 'true' ke DashboardPage
                                  Navigator.pop(context, true); 
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Connection error"), backgroundColor: Colors.red)
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: isScanned ? 5 : 0,
                      ),
                      child: Text("SUBMIT ATTENDANCE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isScanned ? Colors.white : const Color(0xFF94A3B8), letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}