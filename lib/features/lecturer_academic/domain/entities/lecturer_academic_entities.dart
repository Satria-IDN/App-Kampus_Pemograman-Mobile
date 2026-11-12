import '../../../courses/domain/entities/course_entity.dart';

/// Satu baris jadwal mengajar mingguan.
class LecturerScheduleItem {
  final CourseEntity course;
  final int studentCount;
  final int dayOfWeek; // 1 = Senin ... 7 = Minggu
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String? activeSessionId; // terisi jika sesi mata kuliah ini sedang dibuka

  const LecturerScheduleItem({
    required this.course,
    required this.studentCount,
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

/// Satu pertemuan (sesi) beserta rekap kehadirannya.
class LecturerSessionRecord {
  final String sessionId;
  final String courseId;
  final String courseName;
  final String? roomName;
  final String sessionType; // reguler | workshop | kuliah_tamu
  final DateTime? startedAt;
  final bool isActive;
  final int meetingNumber;
  final int enrolled;
  final int present;
  final int excused; // izin + sakit

  const LecturerSessionRecord({
    required this.sessionId,
    required this.courseId,
    required this.courseName,
    this.roomName,
    required this.sessionType,
    this.startedAt,
    required this.isActive,
    required this.meetingNumber,
    required this.enrolled,
    required this.present,
    required this.excused,
  });

  /// Alpa baru dihitung setelah sesi ditutup.
  int get alpa {
    if (isActive) return 0;
    final a = enrolled - present - excused;
    return a < 0 ? 0 : a;
  }

  double get percentage => enrolled > 0 ? present * 100 / enrolled : 0;
}

/// Seluruh data dashboard dosen.
class LecturerOverview {
  final List<LecturerScheduleItem> schedules;
  final List<CourseEntity> courses; // semua matkul yang diampu
  final Map<String, int> studentCountByCourse;
  final List<LecturerSessionRecord> sessions; // terbaru dulu
  final int totalStudents; // jumlah mahasiswa unik

  const LecturerOverview({
    required this.schedules,
    required this.courses,
    required this.studentCountByCourse,
    required this.sessions,
    required this.totalStudents,
  });

  List<LecturerSessionRecord> get activeSessions =>
      sessions.where((s) => s.isActive).toList();

  int get totalSks => courses.fold(0, (sum, c) => sum + c.sks);

  List<LecturerSessionRecord> sessionsOn(DateTime day) => sessions.where((s) {
        final t = s.startedAt;
        return t != null && t.year == day.year && t.month == day.month && t.day == day.day;
      }).toList();
}
