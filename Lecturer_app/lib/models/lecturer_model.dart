class Lecturer {
  final int? lecturerId;
  final String nama;
  final String username;
  final String password;

  Lecturer({
    this.lecturerId,
    required this.nama,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'lecturer_id': lecturerId,
      'nama': nama,
      'username': username,
      'password': password,
    };
  }

  factory Lecturer.fromMap(Map<String, dynamic> map) {
    return Lecturer(
      lecturerId: map['lecturer_id'],
      nama: map['nama'],
      username: map['username'],
      password: map['password'],
    );
  }
}