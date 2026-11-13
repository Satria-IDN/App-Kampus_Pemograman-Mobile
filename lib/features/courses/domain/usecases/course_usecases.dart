import '../entities/course_admin_entities.dart';
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

class GetAdminCourses {
  final CourseRepository _repo;
  const GetAdminCourses(this._repo);

  Future<List<AdminCourseEntity>> call() => _repo.getAdminCourses();
}

class GetLecturers {
  final CourseRepository _repo;
  const GetLecturers(this._repo);

  Future<List<LecturerOption>> call() => _repo.getLecturers();
}

/// Aturan bisnis pembuatan matkul: kode, nama, SKS 1-6, dosen, dan jam valid.
class CreateCourse {
  final CourseRepository _repo;
  const CreateCourse(this._repo);

  Future<void> call(NewCourseInput input) {
    if (input.code.trim().isEmpty) throw 'Kode mata kuliah wajib diisi.';
    if (input.name.trim().isEmpty) throw 'Nama mata kuliah wajib diisi.';
    if (input.sks < 1 || input.sks > 6) throw 'SKS harus antara 1 dan 6.';
    if (input.lecturerId.isEmpty) throw 'Pilih dosen pengampu.';
    for (final s in input.schedules) {
      if (s.endMinutes <= s.startMinutes) {
        throw 'Jam selesai harus setelah jam mulai.';
      }
    }
    return _repo.createCourse(input);
  }
}

class DeleteCourse {
  final CourseRepository _repo;
  const DeleteCourse(this._repo);

  Future<void> call(String courseId) => _repo.deleteCourse(courseId);
}

class GetStudents {
  final CourseRepository _repo;
  const GetStudents(this._repo);

  Future<List<StudentOption>> call() => _repo.getStudents();
}

class GetEnrolledStudentIds {
  final CourseRepository _repo;
  const GetEnrolledStudentIds(this._repo);

  Future<Set<String>> call(String courseId) => _repo.getEnrolledStudentIds(courseId);
}

class SaveEnrollments {
  final CourseRepository _repo;
  const SaveEnrollments(this._repo);

  Future<void> call(String courseId, Set<String> studentIds) =>
      _repo.saveEnrollments(courseId, studentIds);
}
