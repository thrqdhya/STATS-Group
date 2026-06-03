import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database/database_helper.dart';
import 'screens/lecturer_login_page.dart';
import 'services/local_server_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await DatabaseHelper.instance.database;

  final server =
    LocalServerService();

  await server.startServer();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LecturerLoginPage(),
    ),
  );
}