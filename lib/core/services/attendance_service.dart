import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  static Future<Map<String, dynamic>> submitAttendance({
    required String sessionId,
    required String? studentId,
    required double distance,
    required bool isMocked,
  }) async {
    // 1. Validasi awal di sisi klien
    if (studentId == null) {
      return {
        'success': false,
        'message': 'Autentikasi gagal: Sesi login mahasiswa tidak valid.',
      };
    }

    try {
      // 2. Eksekusi Stored Procedure RPC di Supabase
      final response = await Supabase.instance.client.rpc(
        'record_attendance',
        params: {
          'p_session_id': sessionId,
          'p_student_id': studentId,
          'p_distance': distance,
          'p_is_mocked': isMocked,
        },
      );

      // 3. Response dari fungsi RPC (mengembalikan boolean atau json)
      return {
        'success': response['success'] ?? true,
        'message': response['message'] ?? 'Presensi berhasil dicatat!',
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': e.message, // Menangkap pesan kustom dari database (RAISE EXCEPTION)
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kendala koneksi: $e',
      };
    }
  }
}