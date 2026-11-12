import '../entities/activity_event.dart';
import '../repositories/activity_log_repository.dart';

class GetRecentActivity {
  final ActivityLogRepository _repo;
  const GetRecentActivity(this._repo);

  Future<List<ActivityEvent>> call({int limit = 50}) =>
      _repo.getRecentEvents(limit: limit);
}
