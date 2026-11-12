import '../entities/activity_event.dart';

abstract class ActivityLogRepository {
  /// Kejadian terbaru lebih dulu.
  Future<List<ActivityEvent>> getRecentEvents({int limit = 50});
}
