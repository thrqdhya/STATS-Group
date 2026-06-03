import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(
    Database db,
    int version,
  ) async {

    //Tabel Students
        await db.execute('''
    CREATE TABLE students(
      nim TEXT PRIMARY KEY,
      nama TEXT NOT NULL,
      major TEXT,
      faculty TEXT,
      university TEXT,
      password TEXT DEFAULT 'password123',
      device_id TEXT
    )
    ''');
    
    //Tabel Lecturers
        await db.execute('''
    CREATE TABLE lecturers(
      lecturer_id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT NOT NULL,
      username TEXT UNIQUE,
      password TEXT
    )
    ''');

    //Tabel Courses
        await db.execute('''
    CREATE TABLE courses(
      course_id INTEGER PRIMARY KEY AUTOINCREMENT,
      course_name TEXT NOT NULL,
      lecturer_id INTEGER
    )
    ''');

    //Tabel Student Courses
        await db.execute('''
    CREATE TABLE student_courses(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_nim TEXT,
      course_id INTEGER
    )
    ''');

    //Tabel Sessions
        await db.execute('''
    CREATE TABLE sessions(
      session_id INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal TEXT,
      expires_at TEXT,
      lecturer_id INTEGER,
      course_id INTEGER
    )
    ''');

    //Tabel QR Tokens
        await db.execute('''
    CREATE TABLE qr_tokens(
      token_id INTEGER PRIMARY KEY AUTOINCREMENT,
      token TEXT UNIQUE,
      created_at TEXT,
      expires_at TEXT,
      session_id INTEGER
    )
    ''');

    //Tabel Attendance
        await db.execute('''
    CREATE TABLE attendance_records(
      record_id INTEGER PRIMARY KEY AUTOINCREMENT,
      nim TEXT,
      session_id INTEGER,
      status TEXT DEFAULT 'PRESENT',
      timestamp TEXT
    )
    ''');

        await db.execute('''
    CREATE UNIQUE INDEX unique_attendance
    ON attendance_records(nim, session_id)
    ''');

        await db.insert(
      'lecturers',
      {
        'nama': 'Ramazan Yilmaz',
        'username': 'admin',
        'password': 'admin',
      },
    );

        await db.insert(
      'students',
      {
        'nim': '23670708027',
        'nama': 'Mutia Apriani',
        'major': 'BTBS',
        'faculty': 'Fen',
        'university': 'Bartin',
      },
    );

        await db.insert(
      'students',
      {
        'nim': '22670708061',
        'nama': 'Thoriq',
        'major': 'BTBS',
        'faculty': 'Fen',
        'university': 'Bartin',
      },
    );

      }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}