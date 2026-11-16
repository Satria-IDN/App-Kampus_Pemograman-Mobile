import '../entities/session_roster.dart';
import '../repositories/session_roster_repository.dart';

class GetSessionRoster {
  final SessionRosterRepository _repo;
  const GetSessionRoster(this._repo);

  Future<SessionRoster> call(String sessionId) => _repo.getRoster(sessionId);
}
