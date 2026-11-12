import '../entities/dispensation_entity.dart';
import '../repositories/dispensation_repository.dart';

/// Aturan bisnis pengajuan: alasan jelas, tanggal wajar, lampiran maks. 5 MB.
class SubmitDispensation {
  static const int maxDocumentBytes = 5 * 1024 * 1024;

  final DispensationRepository _repo;
  const SubmitDispensation(this._repo);

  Future<void> call(NewDispensation input) {
    if (input.type != 'izin' && input.type != 'sakit') {
      throw 'Pilih jenis pengajuan: izin atau sakit.';
    }
    if (input.courseId.isEmpty) {
      throw 'Pilih mata kuliah.';
    }
    if (input.reason.trim().length < 5) {
      throw 'Tuliskan alasan dengan jelas (minimal 5 karakter).';
    }

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final diff = input.absenceDate.difference(day).inDays;
    if (diff < -30 || diff > 30) {
      throw 'Tanggal harus dalam rentang 30 hari dari hari ini.';
    }

    final bytes = input.documentBytes;
    if (bytes != null && bytes.length > maxDocumentBytes) {
      throw 'Ukuran lampiran maksimal 5 MB.';
    }
    return _repo.submit(input);
  }
}

class GetStudentDispensations {
  final DispensationRepository _repo;
  const GetStudentDispensations(this._repo);

  Future<List<DispensationEntity>> call(String studentId) => _repo.getForStudent(studentId);
}

class GetCourseDispensations {
  final DispensationRepository _repo;
  const GetCourseDispensations(this._repo);

  Future<List<DispensationEntity>> call(List<String> courseIds, {String? status}) =>
      _repo.getByCourses(courseIds, status: status);
}

class ReviewDispensation {
  final DispensationRepository _repo;
  const ReviewDispensation(this._repo);

  Future<void> call({
    required String id,
    required bool approve,
    required String reviewerId,
    String? note,
  }) =>
      _repo.review(id: id, approve: approve, reviewerId: reviewerId, note: note);
}

class GetDispensationDocumentUrl {
  final DispensationRepository _repo;
  const GetDispensationDocumentUrl(this._repo);

  Future<String?> call(String path) => _repo.getDocumentUrl(path);
}
