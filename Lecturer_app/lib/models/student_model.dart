class Student {
  final String nim;
  final String nama;
  final String? major;
  final String? faculty;
  final String? university;
  final String password;
  final String? deviceId;

  Student({
    required this.nim,
    required this.nama,
    this.major,
    this.faculty,
    this.university,
    this.password = "password123",
    this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nim': nim,
      'nama': nama,
      'major': major,
      'faculty': faculty,
      'university': university,
      'password': password,
      'device_id': deviceId,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      nim: map['nim'],
      nama: map['nama'],
      major: map['major'],
      faculty: map['faculty'],
      university: map['university'],
      password: map['password'] ?? 'password123',
      deviceId: map['device_id'],
    );
  }
}