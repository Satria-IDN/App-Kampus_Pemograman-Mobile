import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/courses/domain/entities/course_entity.dart';

class ClassSessionService {
  static final _supabase = Supabase.instance.client;

  /// Label kategori di UI dosen -> nilai yang disimpan (sesuai PRD).
  static const Map<String, String> _sessionTypeMap = {
    'Reguler': 'reguler',
    'Workshop': 'workshop',
    'Tamu': 'kuliah_tamu',
  };

  /// Membuka sesi baru atau mengambil sesi aktif mata kuliah ini (Dosen).
  /// Titik GPS dan radius diambil dari ruangan yang dikunci admin untuk
  /// mata kuliah tersebut, bukan dari posisi dosen.
  static Future<Map<String, dynamic>> getOrCreateActiveSession({
    required String? lecturerId,
    required CourseEntity course,
    required String sessionType,
  }) async {
    final room = course.room;
    if (room == null) {
      throw 'Mata kuliah ${course.code} belum memiliki ruangan. '
          'Minta admin menetapkan titik GPS ruangannya.';
    }
    if (!room.isActive) {
      throw 'Ruangan ${room.name} sedang dinonaktifkan oleh admin.';
    }

    // 1. Pakai sesi aktif yang sudah ada untuk mata kuliah ini
    final existing = await _supabase
        .from('class_sessions')
        .select()
        .eq('course_id', course.id)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1);

    if (existing.isNotEmpty) {
      return Map<String, dynamic>.from(existing.first);
    }

    // 2. Buat sesi baru dengan salinan (snapshot) koordinat ruangan
    final created = await _supabase
        .from('class_sessions')
        .insert({
          'lecturer_id': lecturerId,
          'course_id': course.id,
          'course_code': course.code,
          'course_name': course.name,
          'room_id': room.id,
          'room_name': room.name,
          'session_type': _sessionTypeMap[sessionType] ?? 'reguler',
          'target_lat': room.lat,
          'target_lng': room.lng,
          'radius_meter': room.radiusMeter,
          'is_active': true,
          'started_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return Map<String, dynamic>.from(created);
  }

  /// Menutup sesi (presensi tidak bisa lagi dicatat setelah ini).
  static Future<void> endSession(String sessionId) async {
    await _supabase.from('class_sessions').update({
      'is_active': false,
      'ended_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
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
