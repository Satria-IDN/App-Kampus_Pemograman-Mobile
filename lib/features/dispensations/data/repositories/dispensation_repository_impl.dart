import '../../domain/entities/dispensation_entity.dart';
import '../../domain/repositories/dispensation_repository.dart';
import '../datasources/dispensation_remote_datasource.dart';

class DispensationRepositoryImpl implements DispensationRepository {
  final DispensationRemoteDataSource _remote;
  DispensationRepositoryImpl([DispensationRemoteDataSource? remote])
      : _remote = remote ?? DispensationRemoteDataSource();

  @override
  Future<void> submit(NewDispensation input) async {
    String? path;
    final bytes = input.documentBytes;
    if (bytes != null) {
      final ext = _safeExtension(input.documentExtension);
      path = '${input.studentId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _remote.uploadDocument(path, bytes, contentType: _contentType(ext));
    }

    await _remote.insert({
      'student_id': input.studentId,
      'course_id': input.courseId,
      'absence_date': _dateOnly(input.absenceDate),
      'type': input.type,
      'reason': input.reason.trim(),
      'document_path': path,
    });
  }

  @override
  Future<List<DispensationEntity>> getForStudent(String studentId) async {
    final rows = await _remote.fetchForStudent(studentId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<DispensationEntity>> getByCourses(List<String> courseIds, {String? status}) async {
    final rows = await _remote.fetchByCourses(courseIds, status: status);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> review({
    required String id,
    required bool approve,
    required String reviewerId,
    String? note,
  }) =>
      _remote.review(
        id: id,
        status: approve ? 'approved' : 'rejected',
        reviewerId: reviewerId,
        note: note,
      );

  @override
  Future<String?> getDocumentUrl(String path) => _remote.signedUrl(path);

  static DispensationEntity _fromRow(Map<String, dynamic> r) {
    final course = r['courses'];
    final student = r['profiles'];
    return DispensationEntity(
      id: r['id'].toString(),
      studentId: r['student_id'].toString(),
      studentName: student is Map<String, dynamic> ? student['name']?.toString() : null,
      studentNim: student is Map<String, dynamic> ? student['identifier_id']?.toString() : null,
      courseId: r['course_id'].toString(),
      courseCode: course is Map<String, dynamic> ? (course['course_code'] ?? '').toString() : '',
      courseName: course is Map<String, dynamic> ? (course['course_name'] ?? '').toString() : '',
      absenceDate: DateTime.parse(r['absence_date'].toString()),
      type: (r['type'] ?? 'izin').toString(),
      reason: (r['reason'] ?? '').toString(),
      status: (r['status'] ?? 'pending').toString(),
      reviewerNote: r['reviewer_note']?.toString(),
      documentPath: r['document_path']?.toString(),
      createdAt: r['created_at'] == null ? null : DateTime.tryParse(r['created_at'].toString())?.toLocal(),
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _safeExtension(String? raw) {
    final ext = (raw ?? 'jpg').toLowerCase().replaceAll('.', '');
    const allowed = ['jpg', 'jpeg', 'png', 'webp'];
    return allowed.contains(ext) ? ext : 'jpg';
  }

  static String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
