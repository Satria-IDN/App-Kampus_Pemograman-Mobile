import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource _remote;
  CourseRepositoryImpl([CourseRemoteDataSource? remote])
      : _remote = remote ?? CourseRemoteDataSource();

  @override
  Future<List<CourseEntity>> getLecturerCourses(String lecturerId) =>
      _remote.fetchLecturerCourses(lecturerId);

  @override
  Future<List<CourseEntity>> getAllCourses() => _remote.fetchAllCourses();

  @override
  Future<void> assignRoom(String courseId, String? roomId) =>
      _remote.assignRoom(courseId, roomId);
}
