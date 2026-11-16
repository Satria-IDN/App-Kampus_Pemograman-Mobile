/// Satu baris daftar kehadiran sebuah sesi.
/// status: hadir | izin | sakit | belum (sesi masih aktif) | alpa (sesi sudah ditutup)
class RosterEntry {
  final String studentId;
  final String name;
  final String nim;
  final String status;
  final DateTime? scannedAt;
  final double? distance;
  final bool enrolled; // false = hadir tetapi tidak terdaftar di KRS matkul ini

  const RosterEntry({
    required this.studentId,
    required this.name,
    required this.nim,
    required this.status,
    this.scannedAt,
    this.distance,
    this.enrolled = true,
  });

  bool get isPresent => status == 'hadir';
  bool get isExcused => status == 'izin' || status == 'sakit';
  bool get isAbsent => status == 'belum' || status == 'alpa';
}

/// Daftar kehadiran lengkap satu sesi.
class SessionRoster {
  final String sessionId;
  final String courseName;
  final bool isActive;
  final DateTime? startedAt;
  final List<RosterEntry> entries;

  const SessionRoster({
    required this.sessionId,
    required this.courseName,
    required this.isActive,
    this.startedAt,
    required this.entries,
  });

  int get presentCount => entries.where((e) => e.isPresent).length;
  int get excusedCount => entries.where((e) => e.isExcused).length;
  int get absentCount => entries.where((e) => e.isAbsent).length;
}
