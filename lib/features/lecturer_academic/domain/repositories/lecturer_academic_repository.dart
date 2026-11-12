import '../entities/lecturer_academic_entities.dart';

abstract class LecturerAcademicRepository {
  Future<LecturerOverview> getOverview(String lecturerId);
}
