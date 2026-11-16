import '../../../courses/data/models/course_model.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../dispensations/data/repositories/dispensation_repository_impl.dart';
import '../../../dispensations/domain/entities/dispensation_entity.dart';
import '../../../dispensations/domain/repositories/dispensation_repository.dart';
import '../../domain/entities/lecturer_academic_entities.dart';
import '../../domain/repositories/lecturer_academic_repository.dart';
import '../datasources/lecturer_academic_remote_datasource.dart';

class LecturerAcademicRepositoryImpl implements LecturerAcademicRepository {
  final LecturerAcademicRemoteDataSource _remote;
  final DispensationRepository _dispensations;

  LecturerAcademicRepositoryImpl([
    LecturerAcademicRemoteDataSource? remote,
    DispensationRepository? dispensations,
  ])  : _remote = remote ?? LecturerAcademicRemoteDataSource(),
        _dispensations = dispensations ?? DispensationRepositoryImpl();

  @override
  Future<LecturerOverview> getOverview(String lecturerId) async {
    final courseRows = await _remote.fetchCourses(lecturerId);

    final courses = <CourseEntity>[];
    final studentCountByCourse = <String, int>{};
    final allStudents = <String>{};

    for (final row in courseRows) {
      final course = CourseModel.fromJson(row);
      courses.add(course);

      final enrolls = row['enrollments'];
      var count = 0;
      if (enrolls is List) {
        for (final e in enrolls) {
          if (e is Map<String, dynamic> && e['student_id'] != null) {
            count++;
            allStudents.add(e['student_id'].toString());
          }
        }
      }
      studentCountByCourse[course.id] = count;
    }

    final courseIds = courses.map((c) => c.id).toList();
    final sessionRows = await _remote.fetchSessions(courseIds);

    // Dispensasi: bila tabel belum ada / gagal dimuat, dashboard tetap jalan.
    var approved = <DispensationEntity>[];
    var pending = <DispensationEntity>[];
    try {
      approved = await _dispensations.getByCourses(courseIds, status: 'approved');
      pending = await _dispensations.getByCourses(courseIds, status: 'pending');
    } catch (_) {}

    // Mahasiswa yang dispensasinya disetujui: kunci "matkul|tanggal" -> id mahasiswa
    final approvedByDay = <String, Set<String>>{};
    for (final d in approved) {
      approvedByDay.putIfAbsent(_dayKey(d.courseId, d.absenceDate), () => <String>{}).add(d.studentId);
    }

    // Nomor pertemuan: urut waktu per mata kuliah
    final byCourse = <String, List<Map<String, dynamic>>>{};
    for (final s in sessionRows) {
      final cid = s['course_id']?.toString();
      if (cid == null) continue;
      byCourse.putIfAbsent(cid, () => []).add(s);
    }
    final meetingNumber = <String, int>{};
    for (final list in byCourse.values) {
      list.sort((a, b) {
        final ta = _sessionTime(a), tb = _sessionTime(b);
        if (ta == null && tb == null) return 0;
        if (ta == null) return -1;
        if (tb == null) return 1;
        return ta.compareTo(tb);
      });
      for (var i = 0; i < list.length; i++) {
        meetingNumber[list[i]['id'].toString()] = i + 1;
      }
    }

    final sessions = <LecturerSessionRecord>[];
    final activeByCourse = <String, String>{};

    for (final s in sessionRows) {
      final cid = s['course_id']?.toString() ?? '';
      final isActive = s['is_active'] == true;
      final id = s['id'].toString();

      var present = 0, excused = 0;
      final presentIds = <String>{};
      final excusedIds = <String>{};
      final logs = s['attendance_logs'];
      if (logs is List) {
        for (final l in logs) {
          if (l is! Map<String, dynamic>) continue;
          final studentId = l['student_id']?.toString();
          switch ((l['status'] ?? '').toString().toLowerCase()) {
            case 'hadir':
              present++;
              if (studentId != null) presentIds.add(studentId);
              break;
            case 'izin':
            case 'sakit':
              excused++;
              if (studentId != null) excusedIds.add(studentId);
              break;
          }
        }
      }

      // Dispensasi disetujui untuk tanggal sesi dihitung izin (hanya sesi yang sudah ditutup)
      if (!isActive) {
        final sessionTime = _sessionTime(s);
        final ids = sessionTime == null ? null : approvedByDay[_dayKey(cid, sessionTime)];
        if (ids != null) {
          for (final studentId in ids) {
            if (!presentIds.contains(studentId) && !excusedIds.contains(studentId)) {
              excused++;
            }
          }
        }
      }

      if (isActive) activeByCourse.putIfAbsent(cid, () => id);

      sessions.add(LecturerSessionRecord(
        sessionId: id,
        courseId: cid,
        courseName: (s['course_name'] ?? '-').toString(),
        roomName: s['room_name']?.toString(),
        sessionType: _normalizeType(s['session_type']?.toString()),
        eventTitle: _cleanTitle(s['event_title']),
        startedAt: _sessionTime(s),
        isActive: isActive,
        meetingNumber: meetingNumber[id] ?? 0,
        enrolled: studentCountByCourse[cid] ?? 0,
        present: present,
        excused: excused,
      ));
    }

    sessions.sort((a, b) {
      final ta = a.startedAt, tb = b.startedAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    final schedules = <LecturerScheduleItem>[];
    for (var i = 0; i < courseRows.length; i++) {
      final scheds = courseRows[i]['course_schedules'];
      if (scheds is! List) continue;
      final course = courses[i];
      for (final sc in scheds) {
        if (sc is! Map<String, dynamic>) continue;
        schedules.add(LecturerScheduleItem(
          course: course,
          studentCount: studentCountByCourse[course.id] ?? 0,
          dayOfWeek: (sc['day_of_week'] as num).toInt(),
          startTime: _hhmm(sc['start_time']),
          endTime: _hhmm(sc['end_time']),
          activeSessionId: activeByCourse[course.id],
        ));
      }
    }
    schedules.sort((a, b) {
      final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
      return byDay != 0 ? byDay : a.startMinutes.compareTo(b.startMinutes);
    });

    return LecturerOverview(
      schedules: schedules,
      courses: courses,
      studentCountByCourse: studentCountByCourse,
      sessions: sessions,
      totalStudents: allStudents.length,
      pendingDispensations: pending,
    );
  }

  static String _dayKey(String courseId, DateTime d) =>
      '$courseId|${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _sessionTime(Map<String, dynamic> s) {
    final raw = s['started_at'] ?? s['created_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  static String? _cleanTitle(dynamic v) {
    final t = v?.toString().trim() ?? '';
    return t.isEmpty ? null : t;
  }

  static String _hhmm(dynamic value) {
    final s = (value ?? '').toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  /// Menyamakan nilai lama ('Reguler', 'Tamu') dengan nilai PRD.
  static String _normalizeType(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'workshop':
        return 'workshop';
      case 'kuliah_tamu':
      case 'tamu':
        return 'kuliah_tamu';
      default:
        return 'reguler';
    }
  }
}
