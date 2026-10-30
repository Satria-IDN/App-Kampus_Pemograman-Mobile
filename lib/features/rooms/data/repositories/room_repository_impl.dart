import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_remote_datasource.dart';
import '../models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _remote;
  RoomRepositoryImpl([RoomRemoteDataSource? remote])
      : _remote = remote ?? RoomRemoteDataSource();

  @override
  Future<List<RoomEntity>> getRooms({bool onlyActive = false}) =>
      _remote.fetchRooms(onlyActive: onlyActive);

  @override
  Future<void> saveRoom(RoomEntity room) =>
      _remote.upsert(RoomModel.fromEntity(room));

  @override
  Future<void> setActive(String id, bool value) => _remote.setActive(id, value);
}
