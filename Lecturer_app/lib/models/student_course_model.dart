class StudentCourse {
  final int? id;
  final String studentNim;
  final int courseId;

  StudentCourse({
    this.id,
    required this.studentNim,
    required this.courseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_nim': studentNim,
      'course_id': courseId,
    };
  }

  factory StudentCourse.fromMap(Map<String, dynamic> map) {
    return StudentCourse(
      id: map['id'],
      studentNim: map['student_nim'],
      courseId: map['course_id'],
    );
  }
}