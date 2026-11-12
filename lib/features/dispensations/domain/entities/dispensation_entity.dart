import 'dart:typed_data';

/// Pengajuan dispensasi (izin / sakit) mahasiswa untuk satu mata kuliah pada satu tanggal.
class DispensationEntity {
  final String id;
  final String studentId;
  final String? studentName;
  final String? studentNim;
  final String courseId;
  final String courseCode;
  final String courseName;
  final DateTime absenceDate;
  final String type; // izin | sakit
  final String reason;
  final String status; // pending | approved | rejected
  final String? reviewerNote;
  final String? documentPath;
  final DateTime? createdAt;

  const DispensationEntity({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentNim,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.absenceDate,
    required this.type,
    required this.reason,
    required this.status,
    this.reviewerNote,
    this.documentPath,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get typeLabel => type == 'sakit' ? 'Sakit' : 'Izin';

  String get statusLabel {
    if (isApproved) return 'Disetujui';
    if (isRejected) return 'Ditolak';
    return 'Menunggu';
  }
}

/// Data untuk membuat pengajuan baru.
class NewDispensation {
  final String studentId;
  final String courseId;
  final DateTime absenceDate;
  final String type; // izin | sakit
  final String reason;
  final Uint8List? documentBytes;
  final String? documentExtension;

  const NewDispensation({
    required this.studentId,
    required this.courseId,
    required this.absenceDate,
    required this.type,
    required this.reason,
    this.documentBytes,
    this.documentExtension,
  });
}
