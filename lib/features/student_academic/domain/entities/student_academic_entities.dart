/// Ringkasan kehadiran satu mata kuliah untuk seorang mahasiswa (FR-08).
class CourseAttendanceSummary {
  /// PRD: batas toleransi maksimal 3 kali alpa.
  static const int maxAlpa = 3;

  final String courseId;
  final String code;
  final String name;
  final int sks;
  final int totalMeetings;
  final int attended;
  final int excused; // izin + sakit
  final int alpa;

  const CourseAttendanceSummary({
    required this.courseId,
    required this.code,
    required this.name,
    required this.sks,
    required this.totalMeetings,
    required this.attended,
    required this.excused,
    required this.alpa,
  });

  bool get hasMeetings => totalMeetings > 0;

  /// (Total Hadir / Total Pertemuan) x 100%
  double get percentage => hasMeetings ? attended * 100 / totalMeetings : 0;

  /// PRD: alpa >= 2 (sisa tinggal 1) -> kartu merah (Critical State).
  bool get isCritical => alpa >= 2;

  bool get isBlocked => alpa >= maxAlpa;

  int get remainingAlpa {
    final r = maxAlpa - alpa;
    return r < 0 ? 0 : r;
  }
}

/// Satu baris jadwal kuliah mingguan.
class ScheduleItem {
  final String courseId;
  final String courseCode;
  final String courseName;
  final String? lecturerName;
  final String? roomName;
  final int dayOfWeek; // 1 = Senin ... 7 = Minggu
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String? activeSessionId; // terisi jika dosen sedang membuka sesi

  const ScheduleItem({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    this.lecturerName,
    this.roomName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.activeSessionId,
  });

  int get startMinutes => _toMinutes(startTime);
  int get endMinutes => _toMinutes(endTime);

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }
}

/// Sesi yang sedang dibuka dosen untuk mata kuliah milik mahasiswa.
class ActiveSessionInfo {
  final String sessionId;
  final String courseCode;
  final String courseName;
  final String? roomName;

  const ActiveSessionInfo({
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    this.roomName,
  });
}

/// Satu baris riwayat kehadiran. status: Hadir | Izin | Sakit | Alpa
class AttendanceRecord {
  final String courseName;
  final String? roomName;
  final DateTime? time;
  final String status;
  final double? distance;

  const AttendanceRecord({
    required this.courseName,
    this.roomName,
    this.time,
    required this.status,
    this.distance,
  });
}

/// Seluruh data akademik yang dibutuhkan dashboard mahasiswa.
class StudentOverview {
  final List<CourseAttendanceSummary> courses;
  final List<ScheduleItem> schedules;
  final List<ActiveSessionInfo> activeSessions;
  final List<AttendanceRecord> history;

  const StudentOverview({
    required this.courses,
    required this.schedules,
    required this.activeSessions,
    required this.history,
  });

  int get totalSks => courses.fold(0, (sum, c) => sum + c.sks);
  int get totalMeetings => courses.fold(0, (sum, c) => sum + c.totalMeetings);
  int get totalAttended => courses.fold(0, (sum, c) => sum + c.attended);

  bool get hasMeetings => totalMeetings > 0;

  double get overallPercentage =>
      hasMeetings ? totalAttended * 100 / totalMeetings : 0;

  /// Jumlah alpa tertinggi di antara mata kuliah (dasar status kuota alpa).
  int get worstAlpa =>
      courses.fold(0, (m, c) => c.alpa > m ? c.alpa : m);
}
