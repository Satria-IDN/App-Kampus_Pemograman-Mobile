import '../../../../core/constants/session_types.dart';
import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../datasources/activity_log_remote_datasource.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  final ActivityLogRemoteDataSource _remote;
  ActivityLogRepositoryImpl([ActivityLogRemoteDataSource? remote])
      : _remote = remote ?? ActivityLogRemoteDataSource();

  @override
  Future<List<ActivityEvent>> getRecentEvents({int limit = 50}) async {
    final results = await Future.wait([
      _remote.fetchSessions(),
      _remote.fetchRooms(),
    ]);
    final sessions = results[0];
    final rooms = results[1];

    final events = <ActivityEvent>[];

    for (final s in sessions) {
      final course = (s['course_name'] ?? '-').toString();
      final room = (s['room_name'] ?? '-').toString();
      final type = SessionTypes.label(SessionTypes.normalize(s['session_type']?.toString()));
      final lecturer = s['profiles'];
      final lecturerName =
          lecturer is Map<String, dynamic> ? (lecturer['name'] ?? '-').toString() : '-';

      events.add(ActivityEvent(
        kind: ActivityKind.sessionOpened,
        title: 'Sesi Presensi Dibuka',
        detail: '$course • $room • $type • oleh $lecturerName',
        time: _parse(s['started_at'] ?? s['created_at']),
      ));

      final endedAt = s['ended_at'];
      if (endedAt != null) {
        events.add(ActivityEvent(
          kind: ActivityKind.sessionClosed,
          title: 'Sesi Presensi Ditutup',
          detail: '$course • ${_count(s['attendance_logs'])} presensi tercatat',
          time: _parse(endedAt),
        ));
      }
    }

    for (final r in rooms) {
      events.add(ActivityEvent(
        kind: ActivityKind.roomAdded,
        title: 'Ruangan Ditambahkan',
        detail: (r['room_name'] ?? '-').toString(),
        time: _parse(r['created_at']),
      ));
    }

    events.sort((a, b) {
      final ta = a.time, tb = b.time;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    return events.take(limit).toList();
  }

  static DateTime? _parse(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  /// Hasil embed `attendance_logs(count)` berbentuk [{count: n}].
  static int _count(dynamic embed) {
    if (embed is List && embed.isNotEmpty) {
      final first = embed.first;
      if (first is Map<String, dynamic>) {
        return (first['count'] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }
}
