import '../entities/dispensation_entity.dart';

abstract class DispensationRepository {
  Future<void> submit(NewDispensation input);

  /// Seluruh pengajuan milik seorang mahasiswa (terbaru dulu).
  Future<List<DispensationEntity>> getForStudent(String studentId);

  /// Pengajuan untuk sekumpulan mata kuliah, opsional difilter status.
  Future<List<DispensationEntity>> getByCourses(List<String> courseIds, {String? status});

  Future<void> review({
    required String id,
    required bool approve,
    required String reviewerId,
    String? note,
  });

  /// Tautan sementara untuk melihat lampiran.
  Future<String?> getDocumentUrl(String path);
}
