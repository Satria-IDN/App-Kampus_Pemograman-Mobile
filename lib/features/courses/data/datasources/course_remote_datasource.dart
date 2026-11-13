import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';

class CourseRemoteDataSource {
  static const String _columns =
      'id, course_code, course_name, sks, '
      'rooms(id, room_name, building, latitude, longitude, radius_meters, is_active)';

  final SupabaseClient _db;
  CourseRemoteDataSource([SupabaseClient? db]) : _db = db ?? Supabase.instance.client;

  Future<List<CourseModel>> fetchLecturerCourses(String lecturerId) async {
    final rows = await _db
        .from('courses')
        .select(_columns)
        .eq('lecturer_id', lecturerId)
        .order('course_name');
    return rows.map<CourseModel>((r) => CourseModel.fromJson(r)).toList();
  }

  Future<List<CourseModel>> fetchAllCourses() async {
    final rows = await _db.from('courses').select(_columns).order('course_name');
    return rows.map<CourseModel>((r) => CourseModel.fromJson(r)).toList();
  }

  Future<void> assignRoom(String courseId, String? roomId) async {
    try {
      await _db.from('courses').update({'room_id': roomId}).eq('id', courseId);
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }

  // --- Manajemen master matkul (admin) ---
  Future<List<Map<String, dynamic>>> fetchAdminCourses() async {
    final rows = await _db
        .from('courses')
        .select(
          'id, course_code, course_name, sks, '
          'profiles!courses_lecturer_id_fkey(name), '
          'rooms(room_name), '
          'course_schedules(day_of_week, start_time, end_time), '
          'enrollments(student_id)',
        )
        .order('course_code');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchLecturers() async {
    final rows = await _db
        .from('profiles')
        .select('id, identifier_id, name')
        .eq('role', 'dosen')
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createCourse({
    required String code,
    required String name,
    required int sks,
    required String lecturerId,
    required List<Map<String, dynamic>> schedules,
  }) async {
    try {
      final inserted = await _db
          .from('courses')
          .insert({
            'course_code': code,
            'course_name': name,
            'sks': sks,
            'lecturer_id': lecturerId,
          })
          .select('id')
          .single();
      final courseId = inserted['id'] as String;

      if (schedules.isNotEmpty) {
        try {
          await _db.from('course_schedules').insert(
                schedules.map((s) => {...s, 'course_id': courseId}).toList(),
              );
        } on PostgrestException {
          // Batalkan matkul agar tidak tersisa data setengah jadi
          await _db.from('courses').delete().eq('id', courseId);
          rethrow;
        }
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw 'Kode mata kuliah atau jadwal sudah ada.';
      throw e.message;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _db.from('courses').delete().eq('id', courseId);
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }

  // --- KRS: peserta mata kuliah ---
  Future<List<Map<String, dynamic>>> fetchStudents() async {
    final rows = await _db
        .from('profiles')
        .select('id, identifier_id, name')
        .eq('role', 'mahasiswa')
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Set<String>> fetchEnrolledStudentIds(String courseId) async {
    final rows = await _db
        .from('enrollments')
        .select('student_id')
        .eq('course_id', courseId);
    return rows.map<String>((r) => r['student_id'].toString()).toSet();
  }

  /// Menyamakan daftar peserta dengan [studentIds]: yang baru ditambah, yang dicabut dihapus.
  Future<void> setEnrollments(String courseId, Set<String> studentIds) async {
    try {
      final current = await fetchEnrolledStudentIds(courseId);
      final toAdd = studentIds.difference(current);
      final toRemove = current.difference(studentIds);

      if (toAdd.isNotEmpty) {
        await _db.from('enrollments').insert(
              toAdd.map((id) => {'student_id': id, 'course_id': courseId}).toList(),
            );
      }
      if (toRemove.isNotEmpty) {
        await _db
            .from('enrollments')
            .delete()
            .eq('course_id', courseId)
            .inFilter('student_id', toRemove.toList());
      }
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }
}
