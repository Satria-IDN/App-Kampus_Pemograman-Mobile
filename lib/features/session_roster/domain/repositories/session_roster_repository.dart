import '../entities/session_roster.dart';

abstract class SessionRosterRepository {
  Future<SessionRoster> getRoster(String sessionId);
}
