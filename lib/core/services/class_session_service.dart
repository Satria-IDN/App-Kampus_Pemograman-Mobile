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
  /// mata kuliah tersebut. Server memastikan sesi hanya dibuka pada hari dan
  /// jam kuliah sesuai jadwal (fungsi database `open_class_session`).
  static Future<Map<String, dynamic>> getOrCreateActiveSession({
    required String? lecturerId,
    required CourseEntity course,
    required String sessionType,
    String? eventTitle,
  }) async {
    if (lecturerId == null) {
      throw 'Data login dosen tidak ditemukan. Silakan login ulang.';
    }
    final room = course.room;
    if (room == null) {
      throw 'Mata kuliah ${course.code} belum memiliki ruangan. '
          'Minta admin menetapkan titik GPS ruangannya.';
    }

    try {
      final result = await _supabase.rpc('open_class_session', params: {
        'p_course_id': course.id,
        'p_lecturer_id': lecturerId,
        'p_session_type': _sessionTypeMap[sessionType] ?? 'reguler',
        'p_event_title': (eventTitle == null || eventTitle.trim().isEmpty) ? null : eventTitle.trim(),
      });

      final map = Map<String, dynamic>.from(result as Map);
      if (map['success'] != true) {
        throw (map['message'] ?? 'Gagal membuka sesi.').toString();
      }
      return Map<String, dynamic>.from(map['session'] as Map);
    } on PostgrestException catch (e) {
      throw 'Gagal membuka sesi: ${e.message}';
    }
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
