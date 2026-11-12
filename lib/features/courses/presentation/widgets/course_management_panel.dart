import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course_admin_entities.dart';
import '../../domain/usecases/course_usecases.dart';

const List<String> _dayNames = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

/// Panel admin: daftar mata kuliah dari database, tambah matkul beserta
/// jadwal mingguan, dan hapus matkul.
class CourseManagementPanel extends StatefulWidget {
  const CourseManagementPanel({super.key});

  @override
  State<CourseManagementPanel> createState() => CourseManagementPanelState();
}

class CourseManagementPanelState extends State<CourseManagementPanel> {
  final CourseRepositoryImpl _repo = CourseRepositoryImpl();

  late final GetAdminCourses _getCourses = GetAdminCourses(_repo);
  late final GetLecturers _getLecturers = GetLecturers(_repo);
  late final CreateCourse _createCourse = CreateCourse(_repo);
  late final DeleteCourse _deleteCourse = DeleteCourse(_repo);

  List<AdminCourseEntity> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _getCourses();
      if (!mounted) return;
      setState(() {
        _courses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.badgeRed : AppColors.badgeGreen,
        content: Text(message),
      ),
    );
  }

  /// Dipanggil dari luar (tombol + di header tab) untuk membuka form matkul.
  Future<void> openEditor() async {
    List<LecturerOption> lecturers;
    try {
      lecturers = await _getLecturers();
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal memuat daftar dosen: $e', error: true);
      return;
    }
    if (!mounted) return;

    if (lecturers.isEmpty) {
      _toast('Belum ada akun dosen. Tambahkan akun dosen di menu Kelola Akun.', error: true);
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CourseEditorSheet(
        lecturers: lecturers,
        onSave: _createCourse.call,
      ),
    );

    if (saved == true) {
      if (!mounted) return;
      _toast('Mata kuliah tersimpan.');
      await _load();
    }
  }

  Future<void> _confirmDelete(AdminCourseEntity course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus mata kuliah?'),
        content: Text(
          '${course.code} - ${course.name} akan dihapus beserta jadwal, KRS, '
          'sesi, dan riwayat presensinya. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.badgeRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _deleteCourse(course.id);
      if (!mounted) return;
      _toast('Mata kuliah ${course.code} dihapus.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = [];

    if (_isLoading) {
      body.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (_error != null) {
      body.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(
              'Gagal memuat mata kuliah.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.badgeRed),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      ));
    } else if (_courses.isEmpty) {
      body.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: const Text(
          'Belum ada mata kuliah. Tekan tombol + untuk menambahkan.',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ));
    } else {
      for (final c in _courses) {
        body.add(_buildCourseTile(c));
        body.add(const SizedBox(height: 10));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Master Kurikulum & Matkul',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textGrey),
                  onPressed: _isLoading ? null : _load,
                ),
                IconButton(
                  tooltip: 'Tambah mata kuliah',
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  onPressed: openEditor,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _isLoading ? 'Memuat data...' : 'Total ${_courses.length} mata kuliah terdaftar',
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        const SizedBox(height: 14),
        ...body,
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCourseTile(AdminCourseEntity c) {
    final scheduleText = c.schedules.isEmpty
        ? 'Jadwal belum diatur'
        : c.schedules
            .map((s) => '${_dayNames[s.dayOfWeek - 1]} ${s.startTime}-${s.endTime}')
            .join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  '${c.sks} SKS • ${c.lecturerName ?? 'Dosen belum diatur'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
                const SizedBox(height: 2),
                Text(scheduleText, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    c.roomName ?? 'Ruangan belum diatur',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: c.roomName == null ? AppColors.badgeOrange : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.badgeRed, size: 20),
            onPressed: () => _confirmDelete(c),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORM TAMBAH MATA KULIAH (BOTTOM SHEET)
// ==========================================
class _ScheduleDraft {
  int dayOfWeek;
  TimeOfDay start;
  TimeOfDay end;

  _ScheduleDraft({required this.dayOfWeek, required this.start, required this.end});

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  CourseScheduleEntity toEntity() => CourseScheduleEntity(
        dayOfWeek: dayOfWeek,
        startTime: _fmt(start),
        endTime: _fmt(end),
      );
}

class _CourseEditorSheet extends StatefulWidget {
  final List<LecturerOption> lecturers;
  final Future<void> Function(NewCourseInput input) onSave;

  const _CourseEditorSheet({required this.lecturers, required this.onSave});

  @override
  State<_CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<_CourseEditorSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sksCtrl;

  String? _lecturerId;
  final List<_ScheduleDraft> _schedules = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
    _nameCtrl = TextEditingController();
    _sksCtrl = TextEditingController(text: '3');
    if (widget.lecturers.length == 1) {
      _lecturerId = widget.lecturers.first.id;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _sksCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _addSchedule() {
    setState(() {
      _schedules.add(_ScheduleDraft(
        dayOfWeek: DateTime.now().weekday,
        start: const TimeOfDay(hour: 8, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 0),
      ));
    });
  }

  Future<void> _pickTime(_ScheduleDraft draft, {required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? draft.start : draft.end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        draft.start = picked;
      } else {
        draft.end = picked;
      }
    });
  }

  Future<void> _save() async {
    final sks = int.tryParse(_sksCtrl.text.trim());
    if (sks == null) {
      setState(() => _error = 'SKS harus berupa angka.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        NewCourseInput(
          code: _codeCtrl.text,
          name: _nameCtrl.text,
          sks: sks,
          lecturerId: _lecturerId ?? '',
          schedules: _schedules.map((d) => d.toEntity()).toList(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Mata Kuliah',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _decoration('Kode', hint: 'IF404'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _sksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('SKS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: _decoration('Nama mata kuliah'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _lecturerId,
              isExpanded: true,
              decoration: _decoration('Dosen pengampu'),
              items: widget.lecturers
                  .map((l) => DropdownMenuItem<String>(
                        value: l.id,
                        child: Text('${l.name} (${l.identifierId})', overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _lecturerId = v),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jadwal mingguan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                TextButton.icon(
                  onPressed: _addSchedule,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah jadwal', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_schedules.isEmpty)
              const Text(
                'Belum ada jadwal. Boleh dikosongkan dan diisi nanti.',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ..._schedules.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: d.dayOfWeek,
                        isExpanded: true,
                        decoration: _decoration('Hari'),
                        items: List.generate(
                          7,
                          (n) => DropdownMenuItem<int>(value: n + 1, child: Text(_dayNames[n])),
                        ),
                        onChanged: (v) => setState(() => d.dayOfWeek = v ?? d.dayOfWeek),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => _pickTime(d, isStart: true),
                        child: Text(_fmt(d.start), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('-'),
                    ),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => _pickTime(d, isStart: false),
                        child: Text(_fmt(d.end), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.badgeRed),
                      onPressed: () => setState(() => _schedules.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.badgeRed)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Simpan Mata Kuliah',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
