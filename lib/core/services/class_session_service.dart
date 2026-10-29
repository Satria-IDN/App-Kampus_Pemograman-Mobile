import 'package:supabase_flutter/supabase_flutter.dart';
import 'geofence_service.dart';

class ClassSessionService {
  static final _supabase = Supabase.instance.client;

    // Membuka sesi baru dengan GPS dinamis atau mengambil sesi aktif yang sudah ada (Dosen)
  static Future<Map<String, dynamic>> getOrCreateActiveSession({
    required String? lecturerId,
    required String courseCode,
    required String courseName,
    required String roomName,
    required String sessionType,
    int radius = 50,
  }) async {
    // 1. Ambil koordinat GPS riil dosen via GeofenceService
    final position = await GeofenceService.getCurrentPosition();

    // 2. Cek apakah ada sesi aktif untuk matkul ini
    Map<String, dynamic>? session = await _supabase
        .from('class_sessions')
        .select()
        .eq('course_code', courseCode)
        .eq('is_active', true)
        .maybeSingle();

    // 3. Jika belum ada, buat sesi baru di Supabase
    session ??= await _supabase
        .from('class_sessions')
        .insert({
      'lecturer_id': lecturerId,
      'course_code': courseCode,
      'course_name': courseName,
      'room_name': roomName,
      'session_type': sessionType,
      'target_lat': position.latitude,
      'target_lng': position.longitude,
      'radius_meter': radius,
      'is_active': true,
    })
        .select()
        .single();

    return session;
  }

  /// Mengambil titik koordinat target dan radius sesi aktif (Mahasiswa)
  static Future<Map<String, dynamic>> getSessionLocation(String sessionId) async {
    return await _supabase
        .from('class_sessions')
        .select('target_lat, target_lng, radius_meter')
        .eq('id', sessionId)
        .single();
  }
}