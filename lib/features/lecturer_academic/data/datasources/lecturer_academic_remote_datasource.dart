import 'package:supabase_flutter/supabase_flutter.dart';

/// Mengambil data mentah dari Supabase. Pengolahan ada di repository.
class LecturerAcademicRemoteDataSource {
  final SupabaseClient _db;
  LecturerAcademicRemoteDataSource([SupabaseClient? db])
      : _db = db ?? Supabase.instance.client;

  /// Matkul yang diampu beserta ruangan, jadwal, dan daftar mahasiswa (KRS).
  Future<List<Map<String, dynamic>>> fetchCourses(String lecturerId) async {
    final rows = await _db
        .from('courses')
        .select(
          'id, course_code, course_name, sks, '
          'rooms(id, room_name, building, latitude, longitude, radius_meters, is_active), '
          'course_schedules(day_of_week, start_time, end_time), '
          'enrollments(student_id)',
        )
        .eq('lecturer_id', lecturerId)
        .order('course_name');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Seluruh sesi matkul tersebut beserta status presensi tiap mahasiswa.
  Future<List<Map<String, dynamic>>> fetchSessions(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];
    final rows = await _db
        .from('class_sessions')
        .select(
          'id, course_id, course_name, room_name, session_type, is_active, '
          'started_at, created_at, attendance_logs(student_id, status)',
        )
        .inFilter('course_id', courseIds)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
