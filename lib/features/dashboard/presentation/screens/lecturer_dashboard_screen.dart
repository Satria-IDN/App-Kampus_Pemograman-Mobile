import 'package:flutter/material.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/class_session_service.dart';
import 'lecturer_qr_projector_screen.dart';
import '../../../courses/data/repositories/course_repository_impl.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/domain/usecases/course_usecases.dart';

class LecturerDashboardScreen extends StatefulWidget {
  final UserModel? user;
  const LecturerDashboardScreen({super.key, this.user});

  @override
  State<LecturerDashboardScreen> createState() => _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  int _currentNavIndex = 0; // 0: Beranda, 1: Jadwal, 2: Riwayat, 3: Profil
  String _selectedCategory = 'Reguler'; // Reguler, Workshop, Tamu

  final GetLecturerCourses _getLecturerCourses = GetLecturerCourses(CourseRepositoryImpl());

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.badgeRed, content: Text(text)),
    );
  }

  // Dosen memilih mata kuliah yang diampu; ruangan & titik GPS mengikuti pengaturan admin
  Future<void> _openCoursePicker() async {
    final lecturerId = widget.user?.id;
    if (lecturerId == null) {
      _showMessage('Data login tidak ditemukan. Silakan login ulang.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    List<CourseEntity> courses;
    try {
      courses = await _getLecturerCourses(lecturerId);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // tutup loading
      _showMessage('Gagal memuat mata kuliah: $e');
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // tutup loading

    if (courses.isEmpty) {
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
              const SizedBox(height: 8),
              ...courses.map((c) {
                final hasRoom = c.room != null;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: hasRoom,
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    hasRoom
                        ? '${c.code} • ${c.room!.name} • radius ${c.room!.radiusMeter} m'
                        : '${c.code} • Ruangan belum diatur admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasRoom ? AppColors.textGrey : AppColors.badgeOrange,
                    ),
                  ),
                  trailing: Icon(
                    hasRoom ? Icons.chevron_right_rounded : Icons.warning_amber_rounded,
                    color: hasRoom ? AppColors.textGrey : AppColors.badgeOrange,
                  ),
                  onTap: hasRoom ? () => Navigator.pop(ctx, c) : null,
                );
              }),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LecturerQrProjectorScreen(
            sessionId: session['id'].toString(),
            courseName: course.name,
            roomName: course.room?.name ?? '-',
          ),
        ),
      );
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
  // TAB 0: BERANDA DOSEN
  // ==========================================
  Widget _buildTabBeranda(String name, String nidn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(),
          const SizedBox(height: 14),

          // Tanggal & Status Badge Sesi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textGrey),
                  SizedBox(width: 6),
                  Text('Kamis, 24 Oktober 2026', style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: AppColors.badgeGreen, size: 7),
                    SizedBox(width: 5),
                    Text('Sesi Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.badgeGreen)),
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
                      child: const Text('70 Mahasiswa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('2 Kelas Aktif Mengajar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMetricTile(count: '42', label: 'Hadir', sublabel: 'Tepat Waktu', accentColor: AppColors.badgeGreen, bgColor: const Color(0xFFF0FDF4))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricTile(count: '2', label: 'Izin', sublabel: 'Terverifikasi', accentColor: AppColors.badgeOrange, bgColor: const Color(0xFFFFFBEB))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricTile(count: '0', label: 'Alpa', sublabel: 'Nihil', accentColor: AppColors.textGrey, bgColor: const Color(0xFFF8FAFC))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hero Card: Kontrol Sesi Presensi Aktif
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
                const Text('KELAS YANG SEDANG DIAMPU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
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
                        children: const [
                          Text('Pemrograman Mobile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          SizedBox(height: 2),
                          Text('Kelas IF-4A • Semester Genap', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic QR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kategori Sesi:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey),
                    ),
                    // Badge penanda bahwa perlindungan Dynamic QR aktif secara default
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Dynamic QR Aktif (30s)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
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
                          children: const [
                            Text('Ruangan mengikuti mata kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            SizedBox(height: 2),
                            Text('Titik GPS & radius dikunci oleh admin', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Buka Sesi (Membuka Mode Proyektor Sesi Riil)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _openCoursePicker(),
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Buka Sesi Presensi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Siap Rilis QR Code (Mode Proyektor)', style: TextStyle(fontSize: 9, color: Color(0xFFD6E4FF))),
                      ],
                    ),
                  ),
                ),
              ],
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

          _buildScheduleTile(
            title: 'Algoritma & Struktur Data',
            subtitle: 'Kelas IF-2B • Ruang 104 • CS/CO : 100% Hadir',
            badgeText: 'Selesai',
            badgeSubtext: '100% Hadir',
            badgeColor: AppColors.badgeGreen,
            badgeBg: const Color(0xFFDCFCE7),
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.badgeGreen,
          ),
          const SizedBox(height: 10),

          _buildScheduleTile(
            title: 'Rekayasa Perangkat Lunak',
            subtitle: 'Kelas IF-3A • Ruang Teori 204',
            badgeText: 'Besok',
            badgeSubtext: '13:00 WIB',
            badgeColor: AppColors.primary,
            badgeBg: const Color(0xFFEEF2FF),
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 14),

          // Kartu Verifikasi Dispensasi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFFFEDD5), shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: AppColors.badgeOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Verifikasi Dispensasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('4 Pengajuan Izin/Sakit & Tugas Luar', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showDispensasiReviewDialog(context),
                  child: const Text('Tinjau', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.badgeOrange)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: JADWAL & AGENDA MENGAJAR
  // ==========================================
  Widget _buildTabJadwalMengajar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jadwal Mengajar Pekan Ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Semester Genap 2024/2025 • Total 12 SKS Pengampu', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 16),

          _buildLecturerClassCard(
            title: 'Pemrograman Mobile',
            subtitle: 'Kelas IF-4A • 3 SKS',
            time: 'Kamis, 08:00 - 09:40 WIB',
            room: 'Lab Komputer 301',
            badgeText: 'Sedang Aktif',
            badgeColor: AppColors.badgeGreen,
            canOpenSession: true,
            onOpen: () => _openCoursePicker(),
          ),
          const SizedBox(height: 12),
          _buildLecturerClassCard(
            title: 'Kecerdasan Buatan & ML',
            subtitle: 'Kelas IF-5B • 3 SKS',
            time: 'Kamis, 13:00 - 15:30 WIB',
            room: 'Auditorium Rektorat',
            badgeText: 'Sesi Hari Ini',
            badgeColor: AppColors.primary,
            canOpenSession: true,
            onOpen: () => _openCoursePicker(),
          ),
          const SizedBox(height: 12),
          _buildLecturerClassCard(
            title: 'Algoritma & Struktur Data',
            subtitle: 'Kelas IF-2B • 3 SKS',
            time: 'Senin, 10:00 - 11:40 WIB',
            room: 'Ruang Teori 104',
            badgeText: 'Selesai Dilaksanakan',
            badgeColor: AppColors.textGrey,
            canOpenSession: false,
            onOpen: () {},
          ),
          const SizedBox(height: 12),
          _buildLecturerClassCard(
            title: 'Rekayasa Perangkat Lunak',
            subtitle: 'Kelas IF-3A • 3 SKS',
            time: 'Jumat, 13:00 - 14:40 WIB',
            room: 'Ruang Teori 204',
            badgeText: 'Jadwal Besok',
            badgeColor: AppColors.badgeOrange,
            canOpenSession: false,
            onOpen: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: RIWAYAT SESI PRESENSI KELAS
  // ==========================================
  Widget _buildTabRiwayatMengajar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Sesi Perkuliahan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Log Berita Acara Perkuliahan (BAP) & Rekap Mahasiswa', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 16),

          _buildHistorySessionCard('Pemrograman Mobile - Pertemuan 8', '17 Okt 2026 • Lab 301', '38 Hadir, 2 Izin, 0 Alpa', '95% Kehadiran'),
          const SizedBox(height: 10),
          _buildHistorySessionCard('Algoritma & Struktur Data - Pertemuan 8', '14 Okt 2026 • Ruang 104', '40 Hadir, 0 Izin, 0 Alpa', '100% Kehadiran'),
          const SizedBox(height: 10),
          _buildHistorySessionCard('Pemrograman Mobile - Pertemuan 7', '10 Okt 2026 • Lab 301', '37 Hadir, 1 Izin, 2 Alpa', '92% Kehadiran'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: PROFIL DOSEN & PENGATURAN
  // ==========================================
  Widget _buildTabProfilDosen(String name, String nidn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              _buildProfileStatBox('Total Kelas', '4 Kelas'),
              const SizedBox(width: 10),
              _buildProfileStatBox('Beban SKS', '12 SKS'),
              const SizedBox(width: 10),
              _buildProfileStatBox('Mahasiswa', '140 Total'),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Pengaturan & Integrasi Perkuliahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                  title: const Text('Interval Rotasi Dynamic QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Interval acak token: 20-30 detik', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.badgeGreen),
                  title: const Text('Kalibrasi Geofence Ruangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Toleransi radius standar: 50 Meter', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                  onTap: () {},
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
        ],
      ),
    );
  }

  // Dialog Tinjau Dispensasi
  void _showDispensasiReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verifikasi Dispensasi Mahasiswa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDispensasiItem('Dimas Prayoga (20240801019)', 'Surat Dokter • Sakit Demam', true),
              const Divider(height: 16),
              _buildDispensasiItem('Nabila Putri (20240801072)', 'Surat BAAK • Lomba Debat Nasional', true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildDispensasiItem(String student, String reason, bool canAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(reason, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: AppColors.badgeGreen, size: 22),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispensasi Disetujui')));
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: AppColors.badgeRed, size: 22),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispensasi Ditolak')));
              },
            ),
          ],
        ),
      ],
    );
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
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
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