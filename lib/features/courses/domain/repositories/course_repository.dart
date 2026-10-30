import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<List<CourseEntity>> getLecturerCourses(String lecturerId);
  Future<List<CourseEntity>> getAllCourses();

  /// roomId null = lepas ruangan dari mata kuliah.
  Future<void> assignRoom(String courseId, String? roomId);
}
