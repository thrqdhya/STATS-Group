class Course {
  final int? courseId;
  final String courseName;
  final int lecturerId;

  Course({
    this.courseId,
    required this.courseName,
    required this.lecturerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'course_id': courseId,
      'course_name': courseName,
      'lecturer_id': lecturerId,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      courseId: map['course_id'],
      courseName: map['course_name'],
      lecturerId: map['lecturer_id'],
    );
  }
}