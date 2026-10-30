class RoomEntity {
  final String? id;
  final String name;
  final String? building;
  final double lat;
  final double lng;
  final int radiusMeter;
  final bool isActive;

  const RoomEntity({
    this.id,
    required this.name,
    this.building,
    required this.lat,
    required this.lng,
    this.radiusMeter = 50,
    this.isActive = true,
  });
}
