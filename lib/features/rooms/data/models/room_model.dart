import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    super.id,
    required super.name,
    super.building,
    required super.lat,
    required super.lng,
    super.radiusMeter,
    super.isActive,
  });

  factory RoomModel.fromJson(Map<String, dynamic> j) => RoomModel(
        id: j['id'] as String?,
        name: j['room_name'] as String,
        building: j['building'] as String?,
        lat: (j['latitude'] as num).toDouble(),
        lng: (j['longitude'] as num).toDouble(),
        radiusMeter: (j['radius_meters'] as num).toInt(),
        isActive: (j['is_active'] as bool?) ?? true,
      );

  factory RoomModel.fromEntity(RoomEntity e) => RoomModel(
        id: e.id,
        name: e.name,
        building: e.building,
        lat: e.lat,
        lng: e.lng,
        radiusMeter: e.radiusMeter,
        isActive: e.isActive,
      );

  Map<String, dynamic> toJson() => {
        'room_name': name.trim(),
        'building': building,
        'latitude': lat,
        'longitude': lng,
        'radius_meters': radiusMeter,
        'is_active': isActive,
      };
}
