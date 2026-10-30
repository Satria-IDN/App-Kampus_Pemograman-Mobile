import '../../../rooms/domain/entities/room_entity.dart';

class CourseEntity {
  final String id;
  final String code;
  final String name;
  final int sks;
  final RoomEntity? room; // ruangan yang dikunci admin untuk matkul ini

  const CourseEntity({
    required this.id,
    required this.code,
    required this.name,
    this.sks = 0,
    this.room,
  });
}
