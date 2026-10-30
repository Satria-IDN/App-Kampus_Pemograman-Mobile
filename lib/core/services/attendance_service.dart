import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  static Future<Map<String, dynamic>> submitAttendance({
    required String sessionId,
    required String? studentId,
    required double distance,
    required bool isMocked,
  }) async {
    if (studentId == null) {
      return {
        'success': false,
        'message': 'Autentikasi gagal: Sesi login mahasiswa tidak valid.',
      };
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'record_attendance',
        params: {
          'p_session_id': sessionId,
          'p_student_id': studentId,
          'p_distance': distance,
          'p_is_mocked': isMocked,
        },
      );

      return {
        'success': response['success'] ?? true,
        'message': response['message'] ?? 'Presensi berhasil dicatat!',
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kendala koneksi: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentHistory(
      String studentId) async {
    final response = await Supabase.instance.client
        .from('attendance_logs')
        .select('*, class_sessions(course_name, room_name)')
        .eq('student_id', studentId)
        .order('scanned_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}