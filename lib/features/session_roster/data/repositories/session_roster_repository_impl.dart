import '../../../dispensations/data/repositories/dispensation_repository_impl.dart';
import '../../../dispensations/domain/repositories/dispensation_repository.dart';
import '../../domain/entities/session_roster.dart';
import '../../domain/repositories/session_roster_repository.dart';
import '../datasources/session_roster_remote_datasource.dart';

class SessionRosterRepositoryImpl implements SessionRosterRepository {
  final SessionRosterRemoteDataSource _remote;
  final DispensationRepository _dispensations;

  SessionRosterRepositoryImpl([
    SessionRosterRemoteDataSource? remote,
    DispensationRepository? dispensations,
  ])  : _remote = remote ?? SessionRosterRemoteDataSource(),
        _dispensations = dispensations ?? DispensationRepositoryImpl();

  @override
  Future<SessionRoster> getRoster(String sessionId) async {
    final session = await _remote.fetchSession(sessionId);
    if (session == null) throw 'Sesi tidak ditemukan.';

    final courseId = session['course_id']?.toString();
    final isActive = session['is_active'] == true;
    final startedAt = _parse(session['started_at'] ?? session['created_at']);

    final enrolledRows = courseId == null ? <Map<String, dynamic>>[] : await _remote.fetchEnrolled(courseId);
    final attendanceRows = await _remote.fetchAttendance(sessionId);

    // Dispensasi yang disetujui untuk matkul dan tanggal sesi ini
    final excuseByStudent = <String, String>{};
    if (courseId != null && startedAt != null) {
      try {
        final approved = await _dispensations.getByCourses([courseId], status: 'approved');
        for (final d in approved) {
          if (_sameDay(d.absenceDate, startedAt)) {
            excuseByStudent[d.studentId] = d.type;
          }
        }
      } catch (_) {
        // Tabel dispensasi opsional; daftar tetap ditampilkan tanpa itu.
      }
    }

    final logByStudent = <String, Map<String, dynamic>>{
      for (final a in attendanceRows)
        if (a['student_id'] != null) a['student_id'].toString(): a,
    };

    final entries = <RosterEntry>[];
    final seen = <String>{};

    for (final row in enrolledRows) {
      final id = row['student_id']?.toString();
      if (id == null) continue;
      seen.add(id);

      final profile = row['profiles'];
      final name = profile is Map<String, dynamic> ? (profile['name'] ?? 'Mahasiswa').toString() : 'Mahasiswa';
      final nim = profile is Map<String, dynamic> ? (profile['identifier_id'] ?? '-').toString() : '-';

      final log = logByStudent[id];
      String status;
      if (log != null) {
        status = _normalizeStatus(log['status']?.toString());
      } else if (excuseByStudent.containsKey(id)) {
        status = excuseByStudent[id]!;
      } else {
        status = isActive ? 'belum' : 'alpa';
      }

      entries.add(RosterEntry(
        studentId: id,
        name: name,
        nim: nim,
        status: status,
        scannedAt: log == null ? null : _parse(log['scanned_at']),
        distance: log == null ? null : (log['verified_distance'] as num?)?.toDouble(),
      ));
    }

    // Yang hadir tetapi tidak terdaftar di KRS matkul ini (misalnya peserta event)
    for (final a in attendanceRows) {
      final id = a['student_id']?.toString();
      if (id == null || seen.contains(id)) continue;
      final profile = a['profiles'];
      entries.add(RosterEntry(
        studentId: id,
        name: profile is Map<String, dynamic> ? (profile['name'] ?? 'Mahasiswa').toString() : 'Mahasiswa',
        nim: profile is Map<String, dynamic> ? (profile['identifier_id'] ?? '-').toString() : '-',
        status: _normalizeStatus(a['status']?.toString()),
        scannedAt: _parse(a['scanned_at']),
        distance: (a['verified_distance'] as num?)?.toDouble(),
        enrolled: false,
      ));
    }

    // Yang tidak hadir di atas, lalu izin/sakit, lalu hadir; tiap kelompok urut nama
    int rank(RosterEntry e) => e.isAbsent ? 0 : (e.isExcused ? 1 : 2);
    entries.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return SessionRoster(
      sessionId: sessionId,
      courseName: (session['course_name'] ?? '-').toString(),
      sessionType: _normalizeType(session['session_type']?.toString()),
      isActive: isActive,
      startedAt: startedAt,
      entries: entries,
    );
  }

  static String _normalizeStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'izin':
        return 'izin';
      case 'sakit':
        return 'sakit';
      case 'hadir':
        return 'hadir';
      default:
        return 'alpa';
    }
  }

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

  static DateTime? _parse(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
