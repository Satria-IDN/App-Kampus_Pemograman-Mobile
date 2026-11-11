import '../entities/student_academic_entities.dart';

abstract class StudentAcademicRepository {
  Future<StudentOverview> getOverview(String studentId);
}
