import '../../domain/entities/course_admin_entities.dart';
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

  @override
  Future<List<AdminCourseEntity>> getAdminCourses() async {
    final rows = await _remote.fetchAdminCourses();
    return rows.map<AdminCourseEntity>((r) {
      final lecturer = r['profiles'];
      final room = r['rooms'];
      final scheds = r['course_schedules'];

      final schedules = <CourseScheduleEntity>[];
      if (scheds is List) {
        for (final sc in scheds) {
          if (sc is! Map<String, dynamic>) continue;
          schedules.add(CourseScheduleEntity(
            dayOfWeek: (sc['day_of_week'] as num).toInt(),
            startTime: _hhmm(sc['start_time']),
            endTime: _hhmm(sc['end_time']),
          ));
        }
        schedules.sort((a, b) {
          final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
          return byDay != 0 ? byDay : a.startMinutes.compareTo(b.startMinutes);
        });
      }

      return AdminCourseEntity(
        id: r['id'] as String,
        code: r['course_code'] as String,
        name: r['course_name'] as String,
        sks: (r['sks'] as num?)?.toInt() ?? 0,
        lecturerName: lecturer is Map<String, dynamic> ? lecturer['name']?.toString() : null,
        roomName: room is Map<String, dynamic> ? room['room_name']?.toString() : null,
        schedules: schedules,
        studentCount: r['enrollments'] is List ? (r['enrollments'] as List).length : 0,
      );
    }).toList();
  }

  @override
  Future<List<LecturerOption>> getLecturers() async {
    final rows = await _remote.fetchLecturers();
    return rows
        .map<LecturerOption>((r) => LecturerOption(
              id: r['id'] as String,
              identifierId: (r['identifier_id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
            ))
        .toList();
  }

  @override
  Future<void> createCourse(NewCourseInput input) => _remote.createCourse(
        code: input.code.trim().toUpperCase(),
        name: input.name.trim(),
        sks: input.sks,
        lecturerId: input.lecturerId,
        schedules: input.schedules
            .map<Map<String, dynamic>>((s) => {
                  'day_of_week': s.dayOfWeek,
                  'start_time': '${s.startTime}:00',
                  'end_time': '${s.endTime}:00',
                })
            .toList(),
      );

  @override
  Future<void> deleteCourse(String courseId) => _remote.deleteCourse(courseId);

  @override
  Future<void> setSchedules(String courseId, List<CourseScheduleEntity> schedules) =>
      _remote.replaceSchedules(
        courseId,
        schedules
            .map<Map<String, dynamic>>((s) => {
                  'day_of_week': s.dayOfWeek,
                  'start_time': '${s.startTime}:00',
                  'end_time': '${s.endTime}:00',
                })
            .toList(),
      );

  @override
  Future<List<StudentOption>> getStudents() async {
    final rows = await _remote.fetchStudents();
    return rows
        .map<StudentOption>((r) => StudentOption(
              id: r['id'] as String,
              identifierId: (r['identifier_id'] ?? '').toString(),
              name: (r['name'] ?? '').toString(),
            ))
        .toList();
  }

  @override
  Future<Set<String>> getEnrolledStudentIds(String courseId) =>
      _remote.fetchEnrolledStudentIds(courseId);

  @override
  Future<void> saveEnrollments(String courseId, Set<String> studentIds) =>
      _remote.setEnrollments(courseId, studentIds);

  static String _hhmm(dynamic value) {
    final s = (value ?? '').toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}
