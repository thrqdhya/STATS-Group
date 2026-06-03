class AttendanceRecord {
  final int? recordId;
  final String nim;
  final int sessionId;
  final String status;
  final DateTime timestamp;

  AttendanceRecord({
    this.recordId,
    required this.nim,
    required this.sessionId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'nim': nim,
      'session_id': sessionId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      recordId: map['record_id'],
      nim: map['nim'],
      sessionId: map['session_id'],
      status: map['status'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}