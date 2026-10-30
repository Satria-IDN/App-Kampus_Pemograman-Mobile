import '../../../rooms/data/models/room_model.dart';
import '../../domain/entities/course_entity.dart';

class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    required super.code,
    required super.name,
    super.sks,
    super.room,
  });

  /// Mengharapkan hasil select dengan join: `..., rooms(...)`.
  factory CourseModel.fromJson(Map<String, dynamic> j) {
    final r = j['rooms'];
    return CourseModel(
      id: j['id'] as String,
      code: j['course_code'] as String,
      name: j['course_name'] as String,
      sks: (j['sks'] as num?)?.toInt() ?? 0,
      room: r is Map<String, dynamic> ? RoomModel.fromJson(r) : null,
    );
  }
}
