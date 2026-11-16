import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRosterRemoteDataSource {
  final SupabaseClient _db;
  SessionRosterRemoteDataSource([SupabaseClient? db])
      : _db = db ?? Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchSession(String sessionId) async {
    return await _db
        .from('class_sessions')
        .select('id, course_id, course_name, session_type, is_active, started_at, created_at')
        .eq('id', sessionId)
        .maybeSingle();
  }

  /// Peserta mata kuliah (KRS) beserta nama dan NIM.
  Future<List<Map<String, dynamic>>> fetchEnrolled(String courseId) async {
    final rows = await _db
        .from('enrollments')
        .select('student_id, profiles(name, identifier_id)')
        .eq('course_id', courseId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Seluruh presensi pada sesi ini.
  Future<List<Map<String, dynamic>>> fetchAttendance(String sessionId) async {
    final rows = await _db
        .from('attendance_logs')
        .select('student_id, status, scanned_at, verified_distance, profiles(name, identifier_id)')
        .eq('session_id', sessionId);
    return List<Map<String, dynamic>>.from(rows);
  }
}
