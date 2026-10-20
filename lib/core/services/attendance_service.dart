import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  static Future<Map<String, dynamic>> submitAttendance({
    required String sessionId,
    required double distance,
    required bool isMocked,
  }) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'record_attendance',
        params: {
          'p_session_id': sessionId,
          'p_distance': distance,
          'p_is_mock': isMocked,
        },
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}