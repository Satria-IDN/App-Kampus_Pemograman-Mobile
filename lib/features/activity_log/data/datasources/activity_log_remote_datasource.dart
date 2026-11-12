import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityLogRemoteDataSource {
  final SupabaseClient _db;
  ActivityLogRemoteDataSource([SupabaseClient? db])
      : _db = db ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchSessions({int limit = 60}) async {
    final rows = await _db
        .from('class_sessions')
        .select(
          'id, course_name, room_name, session_type, is_active, started_at, '
          'created_at, ended_at, '
          'profiles!class_sessions_lecturer_id_fkey(name), attendance_logs(count)',
        )
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchRooms({int limit = 20}) async {
    final rows = await _db
        .from('rooms')
        .select('room_name, created_at')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}
