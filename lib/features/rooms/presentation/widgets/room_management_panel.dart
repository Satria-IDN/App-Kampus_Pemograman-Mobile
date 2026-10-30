import 'package:flutter/material.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../courses/data/repositories/course_repository_impl.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/domain/usecases/course_usecases.dart';
import '../../data/repositories/room_repository_impl.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/usecases/room_usecases.dart';

/// Panel admin: kelola titik GPS ruangan (kunci koordinat) dan tetapkan
/// ruangan untuk tiap mata kuliah. Semua data tersimpan di Supabase.
class RoomManagementPanel extends StatefulWidget {
  const RoomManagementPanel({super.key});

  @override
  State<RoomManagementPanel> createState() => RoomManagementPanelState();
}

class RoomManagementPanelState extends State<RoomManagementPanel> {
  final RoomRepositoryImpl _roomRepo = RoomRepositoryImpl();
  final CourseRepositoryImpl _courseRepo = CourseRepositoryImpl();

  late final GetRooms _getRooms = GetRooms(_roomRepo);
  late final SaveRoom _saveRoom = SaveRoom(_roomRepo);
  late final SetRoomActive _setRoomActive = SetRoomActive(_roomRepo);
  late final GetAllCourses _getAllCourses = GetAllCourses(_courseRepo);
  late final AssignRoomToCourse _assignRoom = AssignRoomToCourse(_courseRepo);

  List<RoomEntity> _rooms = [];
  List<CourseEntity> _courses = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final rooms = await _getRooms();
      final courses = await _getAllCourses();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
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

  /// Dipanggil dari luar (tombol + di admin panel) untuk membuka form ruangan.
  Future<void> openEditor([RoomEntity? room]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RoomEditorSheet(room: room, onSave: _saveRoom.call),
    );

    if (saved == true) {
      if (!mounted) return;
      _toast('Titik ruangan tersimpan.');
      await _load();
    }
  }

  Future<void> _toggleActive(RoomEntity room, bool value) async {
    final id = room.id;
    if (id == null) return;
    try {
      await _setRoomActive(id, value);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast('$e', error: true);
    }
  }

  Future<void> _changeCourseRoom(CourseEntity course, String? roomId) async {
    try {
      await _assignRoom(course.id, roomId);
      await _load();
      if (!mounted) return;
      _toast('Ruangan ${course.code} diperbarui.');
    } catch (e) {
      if (!mounted) return;
      _toast('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              'Gagal memuat data ruangan.\n$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.badgeRed),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Titik Ruangan (${_rooms.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            TextButton.icon(
              onPressed: () => openEditor(),
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_rooms.isEmpty)
          _emptyBox('Belum ada ruangan. Tekan "Tambah", berdiri di tengah kelas, lalu kunci lokasi.')
        else
          ..._rooms.map(_buildRoomTile),
        const SizedBox(height: 20),
        const Text(
          'Ruangan per Mata Kuliah',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 2),
        const Text(
          'Dosen membuka sesi dari mata kuliah; titik GPS mengikuti ruangan yang dipilih di sini.',
          style: TextStyle(fontSize: 11, color: AppColors.textGrey),
        ),
        const SizedBox(height: 10),
        if (_courses.isEmpty)
          _emptyBox('Belum ada mata kuliah di database.')
        else
          ..._courses.map(_buildCourseRow),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
    );
  }

  Widget _buildRoomTile(RoomEntity room) {
    final detail = '${room.building ?? 'Gedung -'} • Radius ${room.radiusMeter} m';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.meeting_room_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(detail, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                Text(
                  '${room.lat.toStringAsFixed(6)}, ${room.lng.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Switch(
            value: room.isActive,
            activeThumbColor: AppColors.badgeGreen,
            onChanged: (v) => _toggleActive(room, v),
          ),
          IconButton(
            tooltip: 'Ubah titik',
            icon: const Icon(Icons.edit_location_alt_rounded, size: 20, color: AppColors.primary),
            onPressed: () => openEditor(room),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRow(CourseEntity course) {
    final roomIds = _rooms.map((r) => r.id).toSet();
    final currentId = course.room?.id;
    final value = roomIds.contains(currentId) ? currentId : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.code,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  course.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: DropdownButton<String?>(
              isExpanded: true,
              value: value,
              underline: const SizedBox.shrink(),
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Belum diatur', style: TextStyle(color: AppColors.badgeOrange)),
                ),
                ..._rooms.map(
                  (r) => DropdownMenuItem<String?>(
                    value: r.id,
                    child: Text(r.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (roomId) => _changeCourseRoom(course, roomId),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORM TAMBAH / UBAH RUANGAN (BOTTOM SHEET)
// ==========================================
class _RoomEditorSheet extends StatefulWidget {
  final RoomEntity? room;
  final Future<void> Function(RoomEntity room) onSave;

  const _RoomEditorSheet({required this.room, required this.onSave});

  @override
  State<_RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState extends State<_RoomEditorSheet> {
  static const List<int> _radiusOptions = [10, 25, 50];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _buildingCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  int _radius = 50;
  double? _accuracy;
  bool _capturing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _buildingCtrl = TextEditingController(text: r?.building ?? '');
    _latCtrl = TextEditingController(text: r != null ? r.lat.toStringAsFixed(6) : '');
    _lngCtrl = TextEditingController(text: r != null ? r.lng.toStringAsFixed(6) : '');
    _radius = (r?.radiusMeter ?? 50).clamp(10, 50).toInt();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _buildingCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      // Sudah termasuk cek izin dan penolakan Mock GPS.
      final pos = await GeofenceService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
        _accuracy = pos.accuracy;
        _capturing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _capturing = false;
      });
    }
  }

  Future<void> _save() async {
    final lat = double.tryParse(_latCtrl.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lngCtrl.text.trim().replaceAll(',', '.'));
    if (lat == null || lng == null) {
      setState(() => _error = 'Latitude dan longitude harus berupa angka.');
      return;
    }

    final building = _buildingCtrl.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        RoomEntity(
          id: widget.room?.id,
          name: _nameCtrl.text,
          building: building.isEmpty ? null : building,
          lat: lat,
          lng: lng,
          radiusMeter: _radius,
          isActive: widget.room?.isActive ?? true,
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
    final isEdit = widget.room != null;
    final accuracy = _accuracy;
    final accuracyGood = accuracy != null && accuracy <= 20;

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
            Text(
              isEdit ? 'Ubah Titik Ruangan' : 'Tambah Ruangan Baru',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Berdirilah di tengah ruang kelas, tunggu sinyal stabil, lalu kunci lokasi.',
              style: TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              decoration: _decoration('Nama ruangan', hint: 'Contoh: Lab Komputer 301'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _buildingCtrl,
              decoration: _decoration('Gedung / lantai (opsional)', hint: 'Contoh: Gedung B, Lantai 3'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Radius geofence',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _radiusOptions
                  .map(
                    (o) => ChoiceChip(
                      label: Text('$o m'),
                      selected: _radius == o,
                      onSelected: (_) => setState(() => _radius = o),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: _decoration('Latitude'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: _decoration('Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _capturing || _saving ? null : _captureLocation,
                icon: _capturing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                label: Text(
                  _capturing ? 'Mengunci sinyal GPS...' : 'Kuncikan Lokasi Saya Saat Ini',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
            if (accuracy != null) ...[
              const SizedBox(height: 6),
              Text(
                accuracyGood
                    ? 'Lokasi terkunci. Akurasi ±${accuracy.toStringAsFixed(1)} m (baik).'
                    : 'Akurasi ±${accuracy.toStringAsFixed(1)} m kurang baik. Pindah ke area terbuka atau dekat jendela, lalu kunci ulang.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accuracyGood ? AppColors.badgeGreen : AppColors.badgeOrange,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.badgeRed)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving || _capturing ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Simpan Titik Ruangan',
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
