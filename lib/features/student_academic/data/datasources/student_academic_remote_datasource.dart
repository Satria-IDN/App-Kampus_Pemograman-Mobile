import 'package:supabase_flutter/supabase_flutter.dart';

/// Mengambil data mentah dari Supabase. Pengolahan ada di repository.
class StudentAcademicRemoteDataSource {
  final SupabaseClient _db;
  StudentAcademicRemoteDataSource([SupabaseClient? db])
      : _db = db ?? Supabase.instance.client;

  /// KRS mahasiswa beserta matkul, dosen, ruangan, dan jadwal mingguannya.
  Future<List<Map<String, dynamic>>> fetchEnrollments(String studentId) async {
    final rows = await _db
        .from('enrollments')
        .select(
          'courses(id, course_code, course_name, sks, profiles!courses_lecturer_id_fkey(name), '
          'rooms(room_name), course_schedules(day_of_week, start_time, end_time))',
        )
        .eq('student_id', studentId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Seluruh sesi untuk mata kuliah-mata kuliah tersebut.
  Future<List<Map<String, dynamic>>> fetchSessions(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];
    final rows = await _db
        .from('class_sessions')
        .select('id, course_id, course_code, course_name, room_name, session_type, is_active, started_at, created_at')
        .inFilter('course_id', courseIds)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Seluruh presensi milik mahasiswa.
  Future<List<Map<String, dynamic>>> fetchAttendance(String studentId) async {
    final rows = await _db
        .from('attendance_logs')
        .select('session_id, status, scanned_at, verified_distance, class_sessions(course_name, room_name, session_type)')
        .eq('student_id', studentId)
        .order('scanned_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
