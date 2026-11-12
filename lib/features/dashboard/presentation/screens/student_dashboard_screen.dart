import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/services/qr_token_service.dart';
import '../../../../core/services/class_session_service.dart';
import 'dart:convert';
import '../../../../core/services/attendance_service.dart';
import '../../../../core/constants/session_types.dart';
import '../../../../core/widgets/session_type_filter_bar.dart';
import '../../../student_academic/data/repositories/student_academic_repository_impl.dart';
import '../../../student_academic/domain/entities/student_academic_entities.dart';
import '../../../student_academic/domain/usecases/get_student_overview.dart';


class StudentDashboardScreen extends StatefulWidget {
  final UserModel? user;
  const StudentDashboardScreen({super.key, this.user});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentNavIndex = 0; // 0: Beranda, 1: Jadwal, 2: Riwayat, 3: Profil
  late int _selectedWeekday = DateTime.now().weekday; // 1 = Senin ... 7 = Minggu
  String _historyFilter = 'semua'; // filter kategori sesi di Riwayat

  final StudentAcademicRepositoryImpl _academicRepo = StudentAcademicRepositoryImpl();
  late final GetStudentOverview _getOverview = GetStudentOverview(_academicRepo);
  StudentOverview? _overview;
  bool _isLoadingOverview = true;
  String? _overviewError;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.user?.name ?? 'Mahasiswa';
    final studentNim = widget.user?.identifierId ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      // FAB Tengah Aktif: Membuka Modal Dual-Guard Scanner
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _showDualGuardScannerModal(context),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
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
              const SizedBox(width: 48), // Ruang lekukan FAB
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
            _buildTabBeranda(studentName, studentNim),
            _buildTabJadwal(),
            _buildTabRiwayat(),
            _buildTabProfil(studentName, studentNim),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: BERANDA
  // ==========================================
  // ==========================================
  // DATA AKADEMIK (jadwal, riwayat, kuota alpa) dari Supabase
  // ==========================================
  Future<void> _loadOverview() async {
    final studentId = widget.user?.id;
    if (studentId == null) {
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
      final data = await _getOverview(studentId);
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

  String _semesterLabel() {
    final now = DateTime.now();
    if (now.month >= 8) return 'Semester Ganjil ${now.year}/${now.year + 1}';
    if (now.month == 1) return 'Semester Ganjil ${now.year - 1}/${now.year}';
    return 'Semester Genap ${now.year - 1}/${now.year}';
  }

  String _formatDateTime(DateTime? t) {
    if (t == null) return '-';
    final dd = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$dd ${_shortMonthNames[t.month - 1]} ${t.year} • $hh:$mm WIB';
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
            'Gagal memuat data akademik.\n${_overviewError ?? ''}',
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

  /// Status kartu jadwal. Tombol scan hanya aktif jika dosen sudah membuka sesi.
  ({String tag, Color color, bool canScan}) _scheduleStatus(ScheduleItem s, {required bool isToday}) {
    if (!isToday) {
      return (tag: 'Terjadwal', color: AppColors.textGrey, canScan: false);
    }
    if (s.activeSessionId != null) {
      return (tag: 'Sesi Aktif Sekarang', color: AppColors.badgeGreen, canScan: true);
    }
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    if (nowMinutes < s.startMinutes) {
      return (tag: 'Mendatang', color: AppColors.textGrey, canScan: false);
    }
    if (nowMinutes > s.endMinutes) {
      return (tag: 'Selesai', color: AppColors.textGrey, canScan: false);
    }
    return (tag: 'Menunggu dosen membuka sesi', color: AppColors.badgeOrange, canScan: false);
  }

  Widget _scheduleCard(ScheduleItem s, {required bool isToday}) {
    final st = _scheduleStatus(s, isToday: isToday);
    return _buildJadwalItemCard(
      code: s.courseCode,
      title: s.courseName,
      time: '${s.startTime} - ${s.endTime} WIB',
      room: s.roomName ?? 'Ruangan belum diatur',
      lecturer: s.lecturerName ?? '',
      tag: st.tag,
      tagColor: st.color,
      canScan: st.canScan,
    );
  }

  Color _historyColor(String status) {
    switch (status) {
      case 'Hadir':
        return AppColors.badgeGreen;
      case 'Izin':
      case 'Sakit':
        return AppColors.badgeOrange;
      default:
        return AppColors.badgeRed;
    }
  }

  String _historyLabel(AttendanceRecord r) {
    if (r.status == 'Alpa') return 'Alpa (tidak presensi)';
    return r.status;
  }

  Widget _alpaCardFor(CourseAttendanceSummary c) {
    final Color color = c.alpa >= 2
        ? AppColors.badgeRed
        : (c.alpa == 1 ? AppColors.badgeOrange : AppColors.badgeGreen);
    final pct = c.percentage.toStringAsFixed(0);

    String note;
    if (c.isBlocked) {
      note = 'TERCEKAL: batas alpa tercapai. Segera hubungi dosen atau akademik.';
    } else if (c.alpa == 2) {
      note = 'BAHAYA: Sisa 1 kali alpa sebelum pencekalan ujian akhir!';
    } else if (c.alpa == 1) {
      note = 'Perhatian: Kuota tersisa 2 kali kehadiran alpa.';
    } else if (c.hasMeetings) {
      note = 'Aman: Tingkat kehadiran $pct%.';
    } else {
      note = 'Belum ada pertemuan tercatat.';
    }

    final detail = c.hasMeetings
        ? '${c.sks} SKS • $pct% hadir (${c.attended}/${c.totalMeetings})'
        : '${c.sks} SKS • belum ada pertemuan';

    return _buildAlpaCard(
      courseTitle: c.name,
      sks: detail,
      alpaCount: '${c.alpa} / ${CourseAttendanceSummary.maxAlpa} Alpa',
      statusNote: note,
      isCritical: c.isCritical,
      badgeColor: color,
    );
  }

  // ==========================================
  // TAB 0: BERANDA
  // ==========================================
  Widget _buildTabBeranda(String name, String nim) {
    final firstName = name.split(' ').first;
    final o = _overview;

    return _tabScroll([
      _buildAppHeader(name),
      const SizedBox(height: 14),
      Text(
        'Halo, $firstName 👋',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        _semesterLabel(),
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 16),
      if (o == null) _overviewPlaceholder() else ..._berandaContent(o, name, nim),
    ]);
  }

  List<Widget> _berandaContent(StudentOverview o, String name, String nim) {
    final pct = o.overallPercentage;
    final ringValue = o.hasMeetings ? pct / 100 : 0.0;
    final ringText = o.hasMeetings ? '${pct.toStringAsFixed(0)}%' : '-';
    final sessionText = o.hasMeetings ? '${o.totalAttended}/${o.totalMeetings} Sesi Hadir' : 'Belum ada sesi';

    final worst = o.worstAlpa;
    final Color alpaColor = worst >= 2
        ? AppColors.badgeRed
        : (worst == 1 ? AppColors.badgeOrange : AppColors.badgeGreen);
    final String alpaStatus = worst >= 2 ? 'BAHAYA' : (worst == 1 ? 'Perhatian' : 'Aman');
    final String alpaText = 'Jatah Alpa : $alpaStatus ($worst/${CourseAttendanceSummary.maxAlpa})';

    final ipkText = widget.user?.ipk?.toStringAsFixed(2) ?? '-';

    // Jadwal hari ini + sesi aktif yang tidak ada di jadwal hari ini
    final today = DateTime.now().weekday;
    final todays = o.schedules.where((s) => s.dayOfWeek == today).toList();
    final todayCards = <Widget>[];
    for (final s in todays) {
      todayCards.add(_scheduleCard(s, isToday: true));
      todayCards.add(const SizedBox(height: 12));
    }
    final scheduledCodes = todays.map((s) => s.courseCode).toSet();
    for (final a in o.activeSessions) {
      if (scheduledCodes.contains(a.courseCode)) continue;
      todayCards.add(_buildJadwalItemCard(
        code: a.courseCode,
        title: a.courseName,
        time: 'Sesi sedang berlangsung',
        room: a.roomName ?? '-',
        lecturer: '',
        tag: 'Sesi Aktif Sekarang',
        tagColor: AppColors.badgeGreen,
        canScan: true,
      ));
      todayCards.add(const SizedBox(height: 12));
    }
    if (todayCards.isEmpty) {
      todayCards.add(_emptyCard('Tidak ada kuliah terjadwal hari ini.'));
    }

    return [
      // Hero Card Akademik & Presensi
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MAHASISWA AKTIF',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      const Text('Prodi Informatika (S1)', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      const SizedBox(height: 2),
                      Text('NIM: $nim', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: ringValue,
                            strokeWidth: 6,
                            backgroundColor: const Color(0xFFF1F5F9),
                            color: AppColors.primary,
                          ),
                          Center(
                            child: Text(
                              ringText,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sessionText,
                      style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 22, thickness: 1, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                Icon(
                  worst >= 2 ? Icons.warning_amber_rounded : Icons.shield_outlined,
                  size: 16,
                  color: alpaColor,
                ),
                const SizedBox(width: 6),
                Text(
                  alpaText,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: alpaColor),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Banner sesi siap presensi (hanya jika dosen sedang membuka sesi)
      if (o.activeSessions.isNotEmpty) ...[
        InkWell(
          onTap: () => _showDualGuardScannerModal(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD6E4FF)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesi ${o.activeSessions.first.courseName} siap presensi!',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${o.activeSessions.first.roomName ?? '-'} • Ketuk untuk pindai QR sekarang',
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ] else
        const SizedBox(height: 4),

      // Grid 4 Aksi Cepat
      Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.qr_code_2_rounded,
              title: 'Presensi QR',
              subtitle: 'Buka Kamera',
              iconBg: const Color(0xFFEEF2FF),
              iconColor: AppColors.primary,
              onTap: () => _showDualGuardScannerModal(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.calendar_today_rounded,
              title: 'Jadwal',
              subtitle: 'Lihat Kalender',
              iconBg: const Color(0xFFF0FDF4),
              iconColor: AppColors.badgeGreen,
              onTap: () => setState(() => _currentNavIndex = 1),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.assignment_outlined,
              title: 'Izin / Sakit',
              subtitle: 'Upload Dokumen',
              iconBg: const Color(0xFFFFF7ED),
              iconColor: AppColors.badgeOrange,
              onTap: () => _showDispensasiDialog(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.military_tech_outlined,
              title: 'Nilai & SKS',
              subtitle: 'IPK $ipkText',
              iconBg: const Color(0xFFFAF5FF),
              iconColor: const Color(0xFF8B5CF6),
              onTap: () => setState(() => _currentNavIndex = 3),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),

      // Jadwal Hari Ini
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.circle, color: AppColors.primary, size: 8),
              SizedBox(width: 6),
              Text('Jadwal Hari Ini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _currentNavIndex = 1),
            child: const Text('Semua Sesi', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ...todayCards,
      const SizedBox(height: 8),
    ];
  }

  // ==========================================
  // TAB 1: JADWAL MINGGUAN
  // ==========================================
  Widget _buildTabJadwal() {
    final o = _overview;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final isToday = _selectedWeekday == now.weekday;

    final List<Widget> body = [];
    if (o == null) {
      body.add(_overviewPlaceholder());
    } else {
      final items = o.schedules.where((s) => s.dayOfWeek == _selectedWeekday).toList();
      if (items.isEmpty) {
        body.add(_emptyCard('Tidak ada kuliah pada hari ${_fullDayNames[_selectedWeekday - 1]}.'));
      } else {
        for (final s in items) {
          body.add(_scheduleCard(s, isToday: isToday));
          body.add(const SizedBox(height: 12));
        }
      }
    }

    return _tabScroll([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Jadwal Kuliah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          Text(
            o == null ? '' : '${o.totalSks} SKS Aktif',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_monthNames[now.month - 1]} ${now.year}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                7,
                (i) => _buildDayPill(dayNames[i], monday.add(Duration(days: i)).day, i + 1),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text(
        isToday ? 'Perkuliahan Hari Ini' : 'Perkuliahan Hari ${_fullDayNames[_selectedWeekday - 1]}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
      const SizedBox(height: 10),
      ...body,
      const SizedBox(height: 8),
    ]);
  }

  // ==========================================
  // TAB 2: RIWAYAT KEHADIRAN
  // ==========================================
  Widget _buildTabRiwayat() {
    final o = _overview;
    final List<Widget> body = [];
    if (o == null) {
      body.add(_overviewPlaceholder());
    } else {
      final records = _historyFilter == 'semua'
          ? o.history
          : o.history.where((r) => r.sessionType == _historyFilter).toList();

      if (records.isEmpty) {
        body.add(_emptyCard(_historyFilter == 'semua'
            ? 'Belum ada riwayat presensi.'
            : 'Belum ada riwayat untuk kategori ini.'));
      } else {
        for (final r in records) {
          final roomText = r.sessionType == 'reguler'
              ? (r.roomName ?? '-')
              : '${r.roomName ?? '-'} • ${SessionTypes.label(r.sessionType)}';
          body.add(_buildHistoryItem(
            r.courseName,
            _formatDateTime(r.time),
            roomText,
            _historyLabel(r),
            _historyColor(r.status),
          ));
          body.add(const SizedBox(height: 10));
        }
      }
    }

    return _tabScroll([
      const Text('Riwayat Presensi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      const SizedBox(height: 4),
      const Text('Log kehadiran terverifikasi QR dinamis & GPS', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
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
  // TAB 3: PROFIL & TOLERANSI ALPA
  // ==========================================
  Widget _buildTabProfil(String name, String nim) {
    final o = _overview;
    final ipkText = widget.user?.ipk?.toStringAsFixed(2) ?? '-';
    final sksText = '${widget.user?.sksTotal ?? 0} SKS';

    final List<Widget> alpaBody = [];
    if (o == null) {
      alpaBody.add(_overviewPlaceholder());
    } else if (o.courses.isEmpty) {
      alpaBody.add(_emptyCard('Belum ada mata kuliah (KRS) untuk akun ini.'));
    } else {
      for (final c in o.courses) {
        alpaBody.add(_alpaCardFor(c));
        alpaBody.add(const SizedBox(height: 10));
      }
    }

    return _tabScroll([
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(Icons.person, color: AppColors.primary, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('NIM: $nim', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  const SizedBox(height: 2),
                  const Text('Fakultas Ilmu Komputer • Informatika', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          _buildProfileStatBox('Mata Kuliah', '${o?.courses.length ?? 0}'),
          const SizedBox(width: 10),
          _buildProfileStatBox('IPK Kumulatif', ipkText),
          const SizedBox(width: 10),
          _buildProfileStatBox('Total SKS', sksText),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('Status & Batas Toleransi Alpa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          Icon(Icons.info_outline, size: 16, color: AppColors.textGrey),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Maksimal toleransi alpa per matkul adalah 3 kali sebelum pencekalan UAS.',
        style: TextStyle(fontSize: 11, color: AppColors.textGrey),
      ),
      const SizedBox(height: 12),
      ...alpaBody,
      const SizedBox(height: 14),
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
          label: const Text('Keluar dari Akun (Logout)', style: TextStyle(color: AppColors.badgeRed, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildDayPill(String day, int date, int weekday) {
    final isSelected = _selectedWeekday == weekday;
    return InkWell(
      onTap: () => setState(() => _selectedWeekday = weekday),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(day, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : AppColors.textGrey)),
            const SizedBox(height: 4),
            Text('$date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textDark)),
          ],
        ),
      ),
    );
  }

// ==========================================
  // MODAL BOTTOM SHEET: DUAL-GUARD SCANNER (GPS & Geofence Dinamis)
  // ==========================================
// ==========================================
  // MODAL BOTTOM SHEET: DUAL-GUARD SCANNER (Clean Architecture via GeofenceService)
  // ==========================================
  void _showDualGuardScannerModal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Delegasi pengecekan izin & GPS ke GeofenceService
    final permissionError = await GeofenceService.checkAndRequestPermission();
    if (permissionError != null) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.badgeRed,
          content: Text(permissionError),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    bool isProcessingScan = false;

    // 2. Buka Scanner Kamera
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),

              // Header Scanner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dual-Guard Scanner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF065F46), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: const [
                          Icon(Icons.gps_fixed, size: 12, color: AppColors.badgeGreen),
                          SizedBox(width: 4),
                          Text(
                            'GPS Siap',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.badgeGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Kamera Pemindai Riil
              SizedBox(
                width: 260,
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: MobileScanner(
                    onDetect: (capture) async {
                      if (isProcessingScan) return;

                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;

                      final code = barcodes.first.rawValue;
                      if (code == null) return;

                      isProcessingScan = true;

                      // A. Validasi Token Kriptografi Dynamic QR
                      final isValidToken = QrTokenService.validateToken(code);

                      if (isValidToken) {
                        Navigator.pop(ctx); // Tutup scanner kamera

                        messenger.showSnackBar(
                          const SnackBar(
                            duration: Duration(seconds: 1),
                            content: Text('Memvalidasi geofence & mencatat presensi...'),
                          ),
                        );

                        try {
                          // B. Ekstrak session_id dari QR code
                          final payload = jsonDecode(code);
                          final sessionId = payload['session_id'] as String;

                          // C. Ambil ID mahasiswa aktif dari parameter / SessionService
                          final session = await SessionService.getSession();
                          final currentUserId = widget.user?.id ?? session['userId'];

                          if (currentUserId == null) {
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.badgeRed,
                                content: Text('Sesi login tidak valid. Silakan login kembali.'),
                              ),
                            );
                            return;
                          }

                          // D. Ambil koordinat dinamis sesi via ClassSessionService (Clean Architecture)
                          final sessionData = await ClassSessionService.getSessionLocation(sessionId);

                          final double lecturerLat = (sessionData['target_lat'] as num).toDouble();
                          final double lecturerLng = (sessionData['target_lng'] as num).toDouble();
                          final double sessionRadius = ((sessionData['radius_meter'] ?? 50) as num).toDouble();

                          // E. Eksekusi validasi lokasi dinamis & mock detection via GeofenceService
                          final geoResult = await GeofenceService.validateUserLocation(
                            targetLat: lecturerLat,
                            targetLng: lecturerLng,
                            radiusInMeters: sessionRadius,
                            bufferTolerance: 0.0, // PRD: batas tegas <= radius ruangan (maks. 50 m)
                          );

                          if (!geoResult.isWithinRange) {
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.badgeRed,
                                content: Text(geoResult.errorMessage ?? 'Di luar jangkauan presensi kelas!'),
                              ),
                            );
                            return;
                          }

                          // F. Catat presensi ke database via RPC Stored Procedure
                          final response = await AttendanceService.submitAttendance(
                            sessionId: sessionId,
                            studentId: currentUserId,
                            distance: geoResult.distanceInMeters,
                            isMocked: geoResult.isMocked,
                          );

                          if (!context.mounted) return;

                          if (response['success'] == true) {
                            _loadOverview(); // perbarui riwayat, persentase, dan kuota alpa
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.badgeGreen,
                                content: Text('${response['message']} (Jarak: ${geoResult.distanceInMeters.toStringAsFixed(1)}m)'),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.badgeRed,
                                content: Text(response['message'] ?? 'Presensi ditolak.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.badgeRed,
                              content: Text('Gagal memproses presensi: $e'),
                            ),
                          );
                        }
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.badgeRed,
                            content: Text('QR Kadaluarsa atau Tidak Valid! Coba lagi.'),
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          isProcessingScan = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Status Panduan Mahasiswa
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text('Arahkan ke QR Dosen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const Text(
                        'Dual-Guard Protection: Dynamic QR + Radius Geofence Validasi',
                        style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal & Tutup Kamera', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDispensasiDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Pengajuan Dispensasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Silakan unggah surat dokter atau surat tugas resmi sebelum 1x24 jam setelah sesi perkuliahan berakhir.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dokumen izin berhasil dikirim ke Dosen')));
            },
            child: const Text('Pilih Berkas', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildAppHeader(String name) {
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
              backgroundColor: Color(0xFFE0E7FF),
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

  Widget _buildJadwalItemCard({
    required String code,
    required String title,
    required String time,
    required String room,
    required String lecturer,
    required String tag,
    required Color tagColor,
    required bool canScan,
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
              Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('$time • $room', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          if (lecturer.isNotEmpty)
            Text(lecturer, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          if (canScan) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
                onPressed: () => _showDualGuardScannerModal(context),
                icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                label: const Text('Scan Presensi Sekarang', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String time, String room, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text('$time • $room', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
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

  Widget _buildAlpaCard({
    required String courseTitle,
    required String sks,
    required String alpaCount,
    required String statusNote,
    required bool isCritical,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCritical ? Border.all(color: AppColors.badgeRed.withValues(alpha: 0.6), width: 1.2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(courseTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(alpaCount, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(sks, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          const SizedBox(height: 6),
          Text(statusNote, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor)),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}