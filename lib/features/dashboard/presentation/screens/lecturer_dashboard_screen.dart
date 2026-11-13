import 'package:flutter/material.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/class_session_service.dart';
import 'lecturer_qr_projector_screen.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../../core/constants/session_types.dart';
import '../../../../core/widgets/session_type_filter_bar.dart';
import '../../../dispensations/data/repositories/dispensation_repository_impl.dart';
import '../../../dispensations/domain/usecases/dispensation_usecases.dart';
import '../../../dispensations/presentation/widgets/dispensation_review_sheet.dart';
import '../../../lecturer_academic/data/repositories/lecturer_academic_repository_impl.dart';
import '../../../lecturer_academic/domain/entities/lecturer_academic_entities.dart';
import '../../../lecturer_academic/domain/usecases/get_lecturer_overview.dart';

class LecturerDashboardScreen extends StatefulWidget {
  final UserModel? user;
  const LecturerDashboardScreen({super.key, this.user});

  @override
  State<LecturerDashboardScreen> createState() => _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  int _currentNavIndex = 0; // 0: Beranda, 1: Jadwal, 2: Riwayat, 3: Profil
  String _selectedCategory = 'Reguler'; // Reguler, Workshop, Tamu


  final LecturerAcademicRepositoryImpl _academicRepo = LecturerAcademicRepositoryImpl();
  late final GetLecturerOverview _getOverview = GetLecturerOverview(_academicRepo);
  LecturerOverview? _overview;
  bool _isLoadingOverview = true;
  String? _overviewError;
  String _historyFilter = 'semua'; // filter kategori sesi di Riwayat

  final DispensationRepositoryImpl _dispensationRepo = DispensationRepositoryImpl();
  late final ReviewDispensation _reviewDispensation = ReviewDispensation(_dispensationRepo);
  late final GetDispensationDocumentUrl _getDocumentUrl = GetDispensationDocumentUrl(_dispensationRepo);

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.badgeRed, content: Text(text)),
    );
  }

  // Sesi boleh dibuka mulai sekian menit sebelum jam mulai kuliah (sama dengan aturan di database)
  static const int _openLeadMinutes = 15;

  /// Status buka-sesi sebuah matkul: hanya pada hari dan jam kuliah sesuai jadwal,
  /// atau jika sesinya masih aktif (boleh dilanjutkan).
  ({bool canOpen, String reason}) _courseOpenStatus(LecturerOverview o, CourseEntity c) {
    if (c.room == null) {
      return (canOpen: false, reason: 'Ruangan belum diatur admin');
    }
    if (o.activeSessions.any((s) => s.courseId == c.id)) {
      return (canOpen: true, reason: 'Sesi sedang aktif');
    }

    final slots = o.schedules.where((s) => s.course.id == c.id).toList();
    if (slots.isEmpty) {
      return (canOpen: false, reason: 'Jadwal belum diatur admin');
    }

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    for (final s in slots) {
      if (s.dayOfWeek == now.weekday &&
          nowMinutes >= s.startMinutes - _openLeadMinutes &&
          nowMinutes <= s.endMinutes) {
        return (canOpen: true, reason: '${s.startTime} - ${s.endTime} WIB');
      }
    }

    final text = slots
        .map((s) => '${_fullDayNames[s.dayOfWeek - 1]} ${s.startTime}-${s.endTime}')
        .join(', ');
    return (canOpen: false, reason: 'Di luar jadwal ($text)');
  }

  // Dosen memilih mata kuliah yang diampu; hanya matkul yang sedang waktunya yang bisa dibuka
  Future<void> _openCoursePicker() async {
    final o = _overview;
    if (o == null) {
      _showMessage('Data perkuliahan belum termuat. Coba lagi sebentar.');
      return;
    }
    if (o.courses.isEmpty) {
      _showMessage('Belum ada mata kuliah yang diampu akun ini. Hubungi admin.');
      return;
    }

    final selected = await showModalBottomSheet<CourseEntity>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Mata Kuliah',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              const Text(
                'Sesi hanya bisa dibuka pada hari dan jam kuliah sesuai jadwal.',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: o.courses.map((c) {
                    final st = _courseOpenStatus(o, c);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: st.canOpen,
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${c.code} • ${c.room?.name ?? 'Tanpa ruangan'}\n${st.reason}',
                        style: TextStyle(
                          fontSize: 12,
                          color: st.canOpen ? AppColors.textGrey : AppColors.badgeOrange,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        st.canOpen ? Icons.chevron_right_rounded : Icons.lock_clock_rounded,
                        color: st.canOpen ? AppColors.textGrey : AppColors.badgeOrange,
                      ),
                      onTap: st.canOpen ? () => Navigator.pop(ctx, c) : null,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await _startOrOpenClassSession(selected);
  }

  // Membuat atau mengambil sesi kelas aktif via ClassSessionService
  Future<void> _startOrOpenClassSession(CourseEntity course) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final session = await ClassSessionService.getOrCreateActiveSession(
        lecturerId: widget.user?.id,
        course: course,
        sessionType: _selectedCategory,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog loading

      // Masuk ke mode proyektor dengan data sesi riil
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LecturerQrProjectorScreen(
            sessionId: session['id'].toString(),
            courseName: course.name,
            roomName: course.room?.name ?? '-',
          ),
        ),
      );
      if (mounted) _loadOverview();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecturerName = widget.user?.name ?? 'Dosen';
    final lecturerNidn = widget.user?.identifierId ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _openCoursePicker(),
        child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 12,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_filled, label: 'Beranda', index: 0),
              _buildNavItem(icon: Icons.calendar_month_outlined, label: 'Jadwal', index: 1),
              const SizedBox(width: 48), // Lekukan FAB
              _buildNavItem(icon: Icons.history_rounded, label: 'Riwayat', index: 2),
              _buildNavItem(icon: Icons.person_outline_rounded, label: 'Profil', index: 3),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildTabBeranda(lecturerName, lecturerNidn),
            _buildTabJadwalMengajar(),
            _buildTabRiwayatMengajar(),
            _buildTabProfilDosen(lecturerName, lecturerNidn),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DATA DOSEN (jadwal, sesi, rekap) dari Supabase
  // ==========================================
  Future<void> _loadOverview() async {
    final lecturerId = widget.user?.id;
    if (lecturerId == null) {
      setState(() {
        _isLoadingOverview = false;
        _overviewError = 'Data login tidak ditemukan. Silakan login ulang.';
      });
      return;
    }

    setState(() {
      _isLoadingOverview = _overview == null;
      _overviewError = null;
    });

    try {
      final data = await _getOverview(lecturerId);
      if (!mounted) return;
      setState(() {
        _overview = data;
        _isLoadingOverview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOverview = false;
        _overviewError = '$e';
      });
    }
  }

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const List<String> _fullDayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  String _todayLabel() {
    final now = DateTime.now();
    return '${_fullDayNames[now.weekday - 1]}, ${now.day} ${_monthNames[now.month - 1]} ${now.year}';
  }

  String _semesterLabel() {
    final now = DateTime.now();
    if (now.month >= 8) return 'Semester Ganjil ${now.year}/${now.year + 1}';
    if (now.month == 1) return 'Semester Ganjil ${now.year - 1}/${now.year}';
    return 'Semester Genap ${now.year - 1}/${now.year}';
  }

  String _formatDate(DateTime? t) {
    if (t == null) return '-';
    final dd = t.day.toString().padLeft(2, '0');
    return '$dd ${_shortMonthNames[t.month - 1]} ${t.year}';
  }

  Widget _tabScroll(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _overviewPlaceholder() {
    if (_isLoadingOverview) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(
            'Gagal memuat data perkuliahan.\n${_overviewError ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.badgeRed),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _loadOverview, child: const Text('Coba lagi')),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
    );
  }

  // Dosen menyetujui / menolak pengajuan izin dan sakit mahasiswa
  Future<void> _openDispensationReview(LecturerOverview o) async {
    final lecturerId = widget.user?.id;
    if (lecturerId == null) {
      _showMessage('Data login tidak ditemukan. Silakan login ulang.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DispensationReviewSheet(
        items: o.pendingDispensations,
        onReview: (id, approve, note) => _reviewDispensation(
          id: id,
          approve: approve,
          reviewerId: lecturerId,
          note: note,
        ),
        getDocumentUrl: _getDocumentUrl.call,
      ),
    );

    if (mounted) _loadOverview();
  }

  // Kembali ke mode proyektor untuk sesi yang masih aktif
  Future<void> _resumeSession(LecturerSessionRecord s) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerQrProjectorScreen(
          sessionId: s.sessionId,
          courseName: s.courseName,
          roomName: s.roomName ?? '-',
        ),
      ),
    );
    if (mounted) _loadOverview();
  }

  /// Status kartu jadwal. Tombol buka sesi hanya aktif pada hari dan jam kuliah
  /// (mulai 15 menit sebelum jam mulai sampai jam selesai).
  ({String text, Color color, bool canOpen}) _classStatus(LecturerScheduleItem s) {
    final now = DateTime.now();
    if (s.dayOfWeek != now.weekday) {
      return (text: 'Terjadwal', color: AppColors.textGrey, canOpen: false);
    }
    if (s.activeSessionId != null) {
      return (text: 'Sedang Aktif', color: AppColors.badgeGreen, canOpen: true);
    }
    final nowMinutes = now.hour * 60 + now.minute;
    if (nowMinutes < s.startMinutes - _openLeadMinutes) {
      return (text: 'Mulai ${s.startTime}', color: AppColors.primary, canOpen: false);
    }
    if (nowMinutes > s.endMinutes) {
      return (text: 'Selesai Hari Ini', color: AppColors.textGrey, canOpen: false);
    }
    return (text: 'Bisa Dibuka', color: AppColors.badgeGreen, canOpen: true);
  }

  Widget _scheduleTileFor(LecturerScheduleItem s) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    String badgeText;
    String badgeSub = '${s.startTime} WIB';
    Color color;
    Color bg;
    IconData icon;

    if (s.dayOfWeek == now.weekday) {
      if (s.activeSessionId != null) {
        badgeText = 'Berlangsung';
        badgeSub = 'Sesi aktif';
        color = AppColors.badgeGreen;
        bg = const Color(0xFFDCFCE7);
        icon = Icons.play_circle_outline_rounded;
      } else if (nowMinutes > s.endMinutes) {
        badgeText = 'Selesai';
        color = AppColors.textGrey;
        bg = const Color(0xFFF1F5F9);
        icon = Icons.check_circle_outline_rounded;
      } else {
        badgeText = 'Hari ini';
        color = AppColors.primary;
        bg = const Color(0xFFEEF2FF);
        icon = Icons.access_time_rounded;
      }
    } else if (s.dayOfWeek < now.weekday) {
      badgeText = _fullDayNames[s.dayOfWeek - 1];
      color = AppColors.textGrey;
      bg = const Color(0xFFF1F5F9);
      icon = Icons.check_circle_outline_rounded;
    } else {
      badgeText = _fullDayNames[s.dayOfWeek - 1];
      color = AppColors.primary;
      bg = const Color(0xFFEEF2FF);
      icon = Icons.access_time_rounded;
    }

    return _buildScheduleTile(
      title: s.course.name,
      subtitle: '${s.course.code} • ${s.course.room?.name ?? 'Ruangan belum diatur'} • ${s.studentCount} mhs',
      badgeText: badgeText,
      badgeSubtext: badgeSub,
      badgeColor: color,
      badgeBg: bg,
      icon: icon,
      iconColor: color,
    );
  }

  // ==========================================
  // TAB 0: BERANDA DOSEN
  // ==========================================
  Widget _buildTabBeranda(String name, String nidn) {
    final o = _overview;
    final hasActive = o != null && o.activeSessions.isNotEmpty;

    return _tabScroll([
      _buildAppHeader(),
      const SizedBox(height: 14),

      // Tanggal & Status Badge Sesi
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textGrey),
              const SizedBox(width: 6),
              Text(
                _todayLabel(),
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: hasActive ? AppColors.badgeGreen : AppColors.textGrey, size: 7),
                const SizedBox(width: 5),
                Text(
                  hasActive ? 'Sesi Aktif' : 'Tidak Ada Sesi Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasActive ? AppColors.badgeGreen : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      Text(
        'Halo, $name 👋',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.5),
      ),
      const SizedBox(height: 2),
      Text(
        'NIDN: $nidn • Fakultas Ilmu Komputer',
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 16),
      if (o == null) _overviewPlaceholder() else ..._berandaContent(o),
    ]);
  }

  List<Widget> _berandaContent(LecturerOverview o) {
    final now = DateTime.now();
    final activeSessions = o.activeSessions;
    final focus = activeSessions.isNotEmpty ? activeSessions.first : null;

    var present = 0, excused = 0, alpa = 0;
    for (final s in o.sessionsOn(now)) {
      present += s.present;
      excused += s.excused;
      alpa += s.alpa;
    }

    // Daftar pekan ini: mulai hari ini ke depan, lalu hari yang sudah lewat
    final ordered = [
      ...o.schedules.where((s) => s.dayOfWeek >= now.weekday),
      ...o.schedules.where((s) => s.dayOfWeek < now.weekday),
    ];

    return [
      // Card Statistik Kehadiran Hari Ini
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RINGKASAN HARI INI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '${o.totalStudents} Mahasiswa',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              activeSessions.isEmpty ? 'Belum Ada Kelas Aktif' : '${activeSessions.length} Kelas Aktif Mengajar',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricTile(count: '$present', label: 'Hadir', sublabel: 'Hari ini', accentColor: AppColors.badgeGreen, bgColor: const Color(0xFFF0FDF4))),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile(count: '$excused', label: 'Izin', sublabel: 'Izin & sakit', accentColor: AppColors.badgeOrange, bgColor: const Color(0xFFFFFBEB))),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    count: '$alpa',
                    label: 'Alpa',
                    sublabel: 'Sesi selesai',
                    accentColor: alpa > 0 ? AppColors.badgeRed : AppColors.textGrey,
                    bgColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Hero Card: Kontrol Sesi Presensi
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              focus != null ? 'SESI YANG SEDANG BERLANGSUNG' : 'KONTROL SESI PRESENSI',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textGrey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        focus?.courseName ?? 'Belum ada sesi aktif',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        focus != null
                            ? '${focus.roomName ?? '-'} • ${SessionTypes.label(focus.sessionType)} • ${focus.present}/${focus.enrolled} hadir'
                            : 'Pilih mata kuliah untuk membuka sesi presensi',
                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (focus == null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kategori Sesi:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Dynamic QR Aktif (30s)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildCategoryChip('Reguler', Icons.check_circle_rounded),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Workshop', Icons.build_circle_outlined),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Tamu', Icons.groups_outlined),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Ruang & Geofence
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.badgeGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          focus != null ? (focus.roomName ?? '-') : 'Ruangan mengikuti mata kuliah',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        const Text('Titik GPS & radius dikunci oleh admin', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol buka / lanjutkan sesi (mode proyektor)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (focus != null) {
                    _resumeSession(focus);
                  } else {
                    _openCoursePicker();
                  }
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      focus != null ? 'Lanjutkan Sesi' : 'Buka Sesi Presensi',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      focus != null ? 'Kembali ke Mode Proyektor' : 'Siap Rilis QR Code (Mode Proyektor)',
                      style: const TextStyle(fontSize: 9, color: Color(0xFFD6E4FF)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Verifikasi Dispensasi (izin / sakit) mahasiswa
      InkWell(
        onTap: () => _openDispensationReview(o),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.badgeOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Verifikasi Dispensasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(
                      o.pendingDispensations.isEmpty
                          ? 'Tidak ada pengajuan yang menunggu'
                          : '${o.pendingDispensations.length} pengajuan izin / sakit menunggu keputusan',
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              if (o.pendingDispensations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.badgeOrange, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '${o.pendingDispensations.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Daftar Perkuliahan Pekan Ini
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Daftar Perkuliahan Pekan Ini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          TextButton(
            onPressed: () => setState(() => _currentNavIndex = 1),
            child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      const SizedBox(height: 4),
      if (ordered.isEmpty)
        _emptyCard('Belum ada jadwal mengajar. Minta admin mengisi jadwal mata kuliah.')
      else
        ...ordered.take(4).expand((s) => [_scheduleTileFor(s), const SizedBox(height: 10)]),
      const SizedBox(height: 10),
    ];
  }

  // ==========================================
  // TAB 1: JADWAL & AGENDA MENGAJAR
  // ==========================================
  Widget _buildTabJadwalMengajar() {
    final o = _overview;
    final List<Widget> body = [];

    if (o == null) {
      body.add(_overviewPlaceholder());
    } else {
      for (final s in o.schedules) {
        final st = _classStatus(s);
        body.add(_buildLecturerClassCard(
          title: s.course.name,
          subtitle: '${s.course.code} • ${s.course.sks} SKS • ${s.studentCount} mhs',
          time: '${_fullDayNames[s.dayOfWeek - 1]}, ${s.startTime} - ${s.endTime} WIB',
          room: s.course.room?.name ?? 'Ruangan belum diatur',
          badgeText: st.text,
          badgeColor: st.color,
          canOpenSession: st.canOpen,
          onOpen: () => _startOrOpenClassSession(s.course),
        ));
        body.add(const SizedBox(height: 12));
      }

      // Matkul tanpa jadwal tidak bisa membuka sesi sampai admin mengisi jadwalnya
      final scheduledIds = o.schedules.map((s) => s.course.id).toSet();
      for (final c in o.courses.where((c) => !scheduledIds.contains(c.id))) {
        body.add(_buildLecturerClassCard(
          title: c.name,
          subtitle: '${c.code} • ${c.sks} SKS • ${o.studentCountByCourse[c.id] ?? 0} mhs',
          time: 'Jadwal belum diatur, hubungi admin',
          room: c.room?.name ?? 'Ruangan belum diatur',
          badgeText: 'Tanpa Jadwal',
          badgeColor: AppColors.badgeOrange,
          canOpenSession: false,
          onOpen: () => _startOrOpenClassSession(c),
        ));
        body.add(const SizedBox(height: 12));
      }

      if (body.isEmpty) {
        body.add(_emptyCard('Belum ada mata kuliah yang diampu akun ini. Hubungi admin.'));
      }
    }

    return _tabScroll([
      const Text('Jadwal Mengajar Pekan Ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 4),
      Text(
        o == null ? _semesterLabel() : '${_semesterLabel()} • Total ${o.totalSks} SKS Pengampu',
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
      const SizedBox(height: 16),
      ...body,
      const SizedBox(height: 8),
    ]);
  }

  // ==========================================
  // TAB 2: RIWAYAT SESI PRESENSI KELAS
  // ==========================================
  Widget _buildTabRiwayatMengajar() {
    final o = _overview;
    final List<Widget> body = [];

    if (o == null) {
      body.add(_overviewPlaceholder());
    } else {
      final sessions = _historyFilter == 'semua'
          ? o.sessions
          : o.sessions.where((s) => s.sessionType == _historyFilter).toList();

      if (sessions.isEmpty) {
        body.add(_emptyCard(_historyFilter == 'semua'
            ? 'Belum ada sesi perkuliahan.'
            : 'Belum ada sesi untuk kategori ini.'));
      } else {
        for (final s in sessions) {
          final typeSuffix =
              s.sessionType == 'reguler' ? '' : ' • ${SessionTypes.label(s.sessionType)}';
          final recap = s.isActive
              ? '${s.present} Hadir (sesi berlangsung)'
              : '${s.present} Hadir, ${s.excused} Izin, ${s.alpa} Alpa';
          final pct = s.isActive
              ? 'Aktif'
              : (s.enrolled > 0 ? '${s.percentage.toStringAsFixed(0)}% Kehadiran' : '-');

          body.add(_buildHistorySessionCard(
            '${s.courseName} - Pertemuan ${s.meetingNumber}',
            '${_formatDate(s.startedAt)} • ${s.roomName ?? '-'}$typeSuffix',
            recap,
            pct,
          ));
          body.add(const SizedBox(height: 10));
        }
      }
    }

    return _tabScroll([
      const Text('Riwayat Sesi Perkuliahan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 4),
      const Text('Log Berita Acara Perkuliahan (BAP) & Rekap Mahasiswa', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
      const SizedBox(height: 12),
      SessionTypeFilterBar(
        selected: _historyFilter,
        onChanged: (v) => setState(() => _historyFilter = v),
      ),
      const SizedBox(height: 14),
      ...body,
      const SizedBox(height: 10),
    ]);
  }

  // ==========================================
  // TAB 3: PROFIL DOSEN & PENGATURAN
  // ==========================================
  Widget _buildTabProfilDosen(String name, String nidn) {
    final o = _overview;

    return _tabScroll([
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(Icons.school_rounded, color: AppColors.primary, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('NIDN: $nidn', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  const SizedBox(height: 2),
                  const Text('Fakultas Ilmu Komputer • Dosen Tetap', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          _buildProfileStatBox('Total Kelas', '${o?.courses.length ?? 0} Kelas'),
          const SizedBox(width: 10),
          _buildProfileStatBox('Beban SKS', '${o?.totalSks ?? 0} SKS'),
          const SizedBox(width: 10),
          _buildProfileStatBox('Mahasiswa', '${o?.totalStudents ?? 0} Total'),
        ],
      ),
      const SizedBox(height: 20),
      const Text('Pengaturan & Integrasi Perkuliahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Column(
          children: [
            ListTile(
              leading: Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
              title: Text('Rotasi Dynamic QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('Token berganti otomatis setiap 30 detik', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ),
            Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: Icon(Icons.location_on_outlined, color: AppColors.badgeGreen),
              title: Text('Geofence Ruangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('Titik & radius (maks. 50 m) diatur oleh admin', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.badgeRed),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final navigator = Navigator.of(context);
            await SessionService.clearSession();
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          icon: const Icon(Icons.logout_rounded, color: AppColors.badgeRed, size: 18),
          label: const Text('Keluar dari Akun Dosen (Logout)', style: TextStyle(color: AppColors.badgeRed, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildAppHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('CAMPUSPULSE\nBeranda', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.1)),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark, size: 20),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: isSelected ? AppColors.primary : AppColors.textGrey),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.badgeGreen : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : AppColors.textGrey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({required String count, required String label, required String sublabel, required Color accentColor, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor)),
            ],
          ),
          const SizedBox(height: 2),
          Text(sublabel, style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile({
    required String title,
    required String subtitle,
    required String badgeText,
    required String badgeSubtext,
    required Color badgeColor,
    required Color badgeBg,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                Text(badgeSubtext, style: TextStyle(fontSize: 9, color: badgeColor.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerClassCard({
    required String title,
    required String subtitle,
    required String time,
    required String room,
    required String badgeText,
    required Color badgeColor,
    required bool canOpenSession,
    required VoidCallback onOpen,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('$time • $room', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          if (canOpenSession) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
                onPressed: onOpen,
                icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.white),
                label: const Text('Buka Monitor & QR Code', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySessionCard(String title, String detail, String recap, String pct) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  recap,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            pct,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.badgeGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}