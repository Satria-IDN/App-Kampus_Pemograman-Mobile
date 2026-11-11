import '../entities/student_academic_entities.dart';
import '../repositories/student_academic_repository.dart';

class GetStudentOverview {
  final StudentAcademicRepository _repo;
  const GetStudentOverview(this._repo);

  Future<StudentOverview> call(String studentId) => _repo.getOverview(studentId);
}
