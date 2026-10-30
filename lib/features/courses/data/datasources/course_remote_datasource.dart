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
}
