/// Satu slot jadwal mingguan sebuah mata kuliah.
class CourseScheduleEntity {
  final int dayOfWeek; // 1 = Senin ... 7 = Minggu
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"

  const CourseScheduleEntity({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  int get startMinutes => _toMinutes(startTime);
  int get endMinutes => _toMinutes(endTime);

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }
}

/// Mata kuliah untuk tampilan admin (lengkap dengan dosen, ruangan, jadwal).
class AdminCourseEntity {
  final String id;
  final String code;
  final String name;
  final int sks;
  final String? lecturerName;
  final String? roomName;
  final List<CourseScheduleEntity> schedules;
  final int studentCount; // jumlah mahasiswa terdaftar (KRS)

  const AdminCourseEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.sks,
    this.lecturerName,
    this.roomName,
    this.schedules = const [],
    this.studentCount = 0,
  });
}

class LecturerOption {
  final String id;
  final String identifierId;
  final String name;

  const LecturerOption({
    required this.id,
    required this.identifierId,
    required this.name,
  });
}

/// Data untuk membuat mata kuliah baru.
class NewCourseInput {
  final String code;
  final String name;
  final int sks;
  final String lecturerId;
  final List<CourseScheduleEntity> schedules;

  const NewCourseInput({
    required this.code,
    required this.name,
    required this.sks,
    required this.lecturerId,
    this.schedules = const [],
  });
}

class StudentOption {
  final String id;
  final String identifierId; // NIM
  final String name;

  const StudentOption({
    required this.id,
    required this.identifierId,
    required this.name,
  });
}
