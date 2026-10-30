import '../entities/room_entity.dart';

abstract class RoomRepository {
  Future<List<RoomEntity>> getRooms({bool onlyActive = false});

  /// Insert jika id null, update jika id ada.
  Future<void> saveRoom(RoomEntity room);

  Future<void> setActive(String id, bool value);
}
