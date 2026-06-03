class SessionModel {
  final int? sessionId;
  final DateTime tanggal;
  final DateTime expiresAt;
  final int lecturerId;
  final int? courseId;

  SessionModel({
    this.sessionId,
    required this.tanggal,
    required this.expiresAt,
    required this.lecturerId,
    this.courseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'tanggal': tanggal.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'lecturer_id': lecturerId,
      'course_id': courseId,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['session_id'],
      tanggal: DateTime.parse(map['tanggal']),
      expiresAt: DateTime.parse(map['expires_at']),
      lecturerId: map['lecturer_id'],
      courseId: map['course_id'],
    );
  }

  bool isActive() {
    return DateTime.now().isBefore(expiresAt);
  }
}