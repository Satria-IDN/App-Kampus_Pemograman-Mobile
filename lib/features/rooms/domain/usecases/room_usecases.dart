import '../entities/room_entity.dart';
import '../repositories/room_repository.dart';

class GetRooms {
  final RoomRepository _repo;
  const GetRooms(this._repo);

  Future<List<RoomEntity>> call({bool onlyActive = false}) =>
      _repo.getRooms(onlyActive: onlyActive);
}

/// Aturan bisnis: radius 10-50 m (PRD FR-06), koordinat valid, nama wajib.
class SaveRoom {
  static const int minRadius = 10;
  static const int maxRadius = 50;

  final RoomRepository _repo;
  const SaveRoom(this._repo);

  Future<void> call(RoomEntity room) {
    if (room.name.trim().isEmpty) {
      throw 'Nama ruangan wajib diisi.';
    }
    if (room.lat < -90 || room.lat > 90 || room.lng < -180 || room.lng > 180) {
      throw 'Koordinat tidak valid.';
    }
    if (room.lat == 0 && room.lng == 0) {
      throw 'Koordinat belum diisi. Kunci lokasi dulu.';
    }
    if (room.radiusMeter < minRadius || room.radiusMeter > maxRadius) {
      throw 'Radius harus antara $minRadius dan $maxRadius meter.';
    }
    return _repo.saveRoom(room);
  }
}

class SetRoomActive {
  final RoomRepository _repo;
  const SetRoomActive(this._repo);

  Future<void> call(String id, bool value) => _repo.setActive(id, value);
}
