enum ActivityKind { sessionOpened, sessionClosed, roomAdded }

/// Satu kejadian pada log aktivitas sistem (diturunkan dari data nyata).
class ActivityEvent {
  final ActivityKind kind;
  final String title;
  final String detail;
  final DateTime? time;

  const ActivityEvent({
    required this.kind,
    required this.title,
    required this.detail,
    this.time,
  });
}
