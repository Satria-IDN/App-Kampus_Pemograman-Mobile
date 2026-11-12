import '../entities/course_admin_entities.dart';
import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<List<CourseEntity>> getLecturerCourses(String lecturerId);
  Future<List<CourseEntity>> getAllCourses();

  /// roomId null = lepas ruangan dari mata kuliah.
  Future<void> assignRoom(String courseId, String? roomId);

  // --- Manajemen master matkul (admin) ---
  Future<List<AdminCourseEntity>> getAdminCourses();
  Future<List<LecturerOption>> getLecturers();
  Future<void> createCourse(NewCourseInput input);
  Future<void> deleteCourse(String courseId);
}
