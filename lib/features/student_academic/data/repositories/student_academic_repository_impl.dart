import '../../domain/entities/student_academic_entities.dart';
import '../../domain/repositories/student_academic_repository.dart';
import '../datasources/student_academic_remote_datasource.dart';

class StudentAcademicRepositoryImpl implements StudentAcademicRepository {
  final StudentAcademicRemoteDataSource _remote;
  StudentAcademicRepositoryImpl([StudentAcademicRemoteDataSource? remote])
      : _remote = remote ?? StudentAcademicRemoteDataSource();

  @override
  Future<StudentOverview> getOverview(String studentId) async {
    // 1. Mata kuliah yang diambil (KRS)
    final enrollRows = await _remote.fetchEnrollments(studentId);
    final courseMaps = <Map<String, dynamic>>[];
    for (final row in enrollRows) {
      final c = row['courses'];
      if (c is Map<String, dynamic>) courseMaps.add(c);
    }
    final courseIds = courseMaps.map((c) => c['id'] as String).toList();

    // 2. Sesi dan presensi (paralel)
    final results = await Future.wait([
      _remote.fetchSessions(courseIds),
      _remote.fetchAttendance(studentId),
    ]);
    final sessions = results[0];
    final attendanceRows = results[1];

    final attendanceBySession = <String, Map<String, dynamic>>{
      for (final a in attendanceRows)
        if (a['session_id'] != null) a['session_id'] as String: a,
    };

    // 3. Ringkasan per mata kuliah.
    //    Pertemuan dihitung dari sesi yang sudah ditutup, ditambah sesi aktif
    //    yang sudah dipresensi. Sesi aktif yang belum dipresensi belum dihitung
    //    alpa karena mahasiswa masih bisa melakukan presensi.
    final summaries = <CourseAttendanceSummary>[];
    final alpaRecords = <AttendanceRecord>[];

    for (final c in courseMaps) {
      final id = c['id'] as String;
      int meetings = 0, attended = 0, excused = 0, alpa = 0;

      for (final s in sessions.where((s) => s['course_id'] == id)) {
        final att = attendanceBySession[s['id']];
        final isActive = s['is_active'] == true;

        if (att != null) {
          meetings++;
          switch (_normalizeStatus(att['status']?.toString())) {
            case 'Hadir':
              attended++;
              break;
            case 'Izin':
            case 'Sakit':
              excused++;
              break;
            default:
              alpa++;
          }
        } else if (!isActive) {
          meetings++;
          alpa++;
          alpaRecords.add(AttendanceRecord(
            courseName: (s['course_name'] ?? c['course_name'] ?? '-').toString(),
            roomName: s['room_name']?.toString(),
            time: _parseTime(s['started_at'] ?? s['created_at']),
            status: 'Alpa',
          ));
        }
      }

      summaries.add(CourseAttendanceSummary(
        courseId: id,
        code: c['course_code'] as String,
        name: c['course_name'] as String,
        sks: (c['sks'] as num?)?.toInt() ?? 0,
        totalMeetings: meetings,
        attended: attended,
        excused: excused,
        alpa: alpa,
      ));
    }

    // 4. Sesi aktif milik mata kuliah mahasiswa
    final activeSessions = <ActiveSessionInfo>[];
    final activeByCourse = <String, String>{};
    for (final s in sessions.where((s) => s['is_active'] == true)) {
      final courseId = s['course_id'] as String?;
      if (courseId == null) continue;
      activeByCourse.putIfAbsent(courseId, () => s['id'] as String);
      activeSessions.add(ActiveSessionInfo(
        sessionId: s['id'] as String,
        courseCode: (s['course_code'] ?? '').toString(),
        courseName: (s['course_name'] ?? '').toString(),
        roomName: s['room_name']?.toString(),
      ));
    }

    // 5. Jadwal mingguan
    final schedules = <ScheduleItem>[];
    for (final c in courseMaps) {
      final lecturer = c['profiles'];
      final room = c['rooms'];
      final scheds = c['course_schedules'];
      if (scheds is! List) continue;
      for (final sc in scheds) {
        if (sc is! Map<String, dynamic>) continue;
        schedules.add(ScheduleItem(
          courseId: c['id'] as String,
          courseCode: c['course_code'] as String,
          courseName: c['course_name'] as String,
          lecturerName: lecturer is Map<String, dynamic> ? lecturer['name']?.toString() : null,
          roomName: room is Map<String, dynamic> ? room['room_name']?.toString() : null,
          dayOfWeek: (sc['day_of_week'] as num).toInt(),
          startTime: _hhmm(sc['start_time']),
          endTime: _hhmm(sc['end_time']),
          activeSessionId: activeByCourse[c['id']],
        ));
      }
    }
    schedules.sort((a, b) {
      final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
      return byDay != 0 ? byDay : a.startMinutes.compareTo(b.startMinutes);
    });

    // 6. Riwayat: presensi yang tercatat + sesi tertutup yang terlewat (alpa)
    final history = <AttendanceRecord>[];
    for (final a in attendanceRows) {
      final cs = a['class_sessions'];
      history.add(AttendanceRecord(
        courseName: cs is Map<String, dynamic> ? (cs['course_name'] ?? '-').toString() : '-',
        roomName: cs is Map<String, dynamic> ? cs['room_name']?.toString() : null,
        time: _parseTime(a['scanned_at']),
        status: _normalizeStatus(a['status']?.toString()),
        distance: (a['verified_distance'] as num?)?.toDouble(),
      ));
    }
    history.addAll(alpaRecords);
    history.sort((a, b) {
      final ta = a.time, tb = b.time;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    summaries.sort((a, b) => b.alpa.compareTo(a.alpa));

    return StudentOverview(
      courses: summaries,
      schedules: schedules,
      activeSessions: activeSessions,
      history: history,
    );
  }

  static String _normalizeStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      default:
        return 'Alpa';
    }
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String _hhmm(dynamic value) {
    final s = (value ?? '').toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}
