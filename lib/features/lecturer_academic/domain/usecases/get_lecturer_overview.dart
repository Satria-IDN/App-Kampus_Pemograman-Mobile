import '../entities/lecturer_academic_entities.dart';
import '../repositories/lecturer_academic_repository.dart';

class GetLecturerOverview {
  final LecturerAcademicRepository _repo;
  const GetLecturerOverview(this._repo);

  Future<LecturerOverview> call(String lecturerId) => _repo.getOverview(lecturerId);
}
