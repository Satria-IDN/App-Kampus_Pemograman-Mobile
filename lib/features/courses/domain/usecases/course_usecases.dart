import '../entities/course_entity.dart';
import '../repositories/course_repository.dart';

class GetLecturerCourses {
  final CourseRepository _repo;
  const GetLecturerCourses(this._repo);

  Future<List<CourseEntity>> call(String lecturerId) =>
      _repo.getLecturerCourses(lecturerId);
}

class GetAllCourses {
  final CourseRepository _repo;
  const GetAllCourses(this._repo);

  Future<List<CourseEntity>> call() => _repo.getAllCourses();
}

class AssignRoomToCourse {
  final CourseRepository _repo;
  const AssignRoomToCourse(this._repo);

  Future<void> call(String courseId, String? roomId) =>
      _repo.assignRoom(courseId, roomId);
}
