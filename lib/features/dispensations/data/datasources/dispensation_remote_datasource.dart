import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class DispensationRemoteDataSource {
  static const String bucket = 'dispensations';

  static const String _columns =
      'id, student_id, course_id, absence_date, type, reason, status, '
      'reviewer_note, document_path, created_at, '
      'courses(course_code, course_name), '
      'profiles!dispensations_student_id_fkey(name, identifier_id)';

  final SupabaseClient _db;
  DispensationRemoteDataSource([SupabaseClient? db])
      : _db = db ?? Supabase.instance.client;

  Future<void> uploadDocument(String path, Uint8List bytes, {required String contentType}) async {
    try {
      await _db.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
    } on StorageException catch (e) {
      throw 'Gagal mengunggah lampiran: ${e.message}';
    }
  }

  Future<void> insert(Map<String, dynamic> row) async {
    try {
      await _db.from('dispensations').insert(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw 'Pengajuan untuk mata kuliah dan tanggal ini sudah ada.';
      }
      throw e.message;
    }
  }

  Future<List<Map<String, dynamic>>> fetchForStudent(String studentId) async {
    final rows = await _db
        .from('dispensations')
        .select(_columns)
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchByCourses(List<String> courseIds, {String? status}) async {
    if (courseIds.isEmpty) return [];
    var query = _db.from('dispensations').select(_columns).inFilter('course_id', courseIds);
    if (status != null) {
      query = query.eq('status', status);
    }
    final rows = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> review({
    required String id,
    required String status,
    required String reviewerId,
    String? note,
  }) async {
    try {
      await _db.from('dispensations').update({
        'status': status,
        'reviewed_by': reviewerId,
        'reviewer_note': (note == null || note.trim().isEmpty) ? null : note.trim(),
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }

  Future<String?> signedUrl(String path) async {
    try {
      return await _db.storage.from(bucket).createSignedUrl(path, 600);
    } on StorageException {
      return null;
    }
  }
}
