import 'package:flutter/material.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final UserModel? user;
  const StudentDashboardScreen({super.key, this.user});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentNavIndex = 0; // 0: Beranda, 1: Jadwal, 2: Riwayat, 3: Profil
  int _selectedDay = 16; // Tanggal aktif di kalender mingguan
  String _selectedJadwalFilter = 'Semua'; // Semua, Kuliah (KRS), Event

  @override
  Widget build(BuildContext context) {
    final studentName = widget.user?.name ?? 'Satria Wijaya';
    final studentNim = widget.user?.identifierId ?? '20240801048';

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
  Widget _buildTabBeranda(String name, String nim) {
    final firstName = name.split(' ').first;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Text(
            'Semester Genap 2024/2025',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

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
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
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
                            children: const [
                              CircularProgressIndicator(
                                value: 0.92,
                                strokeWidth: 6,
                                backgroundColor: Color(0xFFF1F5F9),
                                color: AppColors.primary,
                              ),
                              Center(
                                child: Text('92%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('23/25 Sesi Hadir', style: TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 22, thickness: 1, color: Color(0xFFF1F5F9)),
                Row(
                  children: const [
                    Icon(Icons.shield_outlined, size: 16, color: AppColors.badgeGreen),
                    SizedBox(width: 6),
                    Text('Jatah Alpa : Aman (0/3)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.badgeGreen)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Banner Sesi Siap Presensi
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Akses 11-15: Sesi Pemrograman Mobile siap presensi!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        SizedBox(height: 2),
                        Text('Lab 301 • Ketuk untuk pindai QR sekarang', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grid 4 Aksi Cepat (Bisa Ditekan)
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
                  subtitle: 'IPK 3.84',
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

          // Card Kelas Aktif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('08:00 - 09:40 WIB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Reguler', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.badgeGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Pemrograman Mobile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 4),
                const Text('Prof. Dr. Ir. Handoko, M.Kom • Lab 301', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showDualGuardScannerModal(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                    label: const Text('Presensi Sekarang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Indikator Status GPS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.circle, color: AppColors.badgeGreen, size: 8),
              SizedBox(width: 6),
              Text('GPS Aktif: Terkoneksi ke BTS Kampus | Dalam Radius Lab 301', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: JADWAL & AGENDA KAMPUS (Figma Screens)
  // ==========================================
  Widget _buildTabJadwal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Jadwal & Agenda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text('22 SKS Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Pills (Semua | Kuliah KRS | Event)
          Row(
            children: [
              _buildFilterChip('Semua'),
              const SizedBox(width: 8),
              _buildFilterChip('Kuliah (KRS)'),
              const SizedBox(width: 8),
              _buildFilterChip('Event'),
            ],
          ),
          const SizedBox(height: 16),

          // Kalender Horizontal Mingguan Interaktif
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Oktober 2026 • Pekan 8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDayPill('Sen', 14),
                    _buildDayPill('Sel', 15),
                    _buildDayPill('Rab', 16),
                    _buildDayPill('Kam', 17),
                    _buildDayPill('Jum', 18),
                    _buildDayPill('Sab', 19),
                    _buildDayPill('Min', 20),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text('Perkuliahan Hari Ini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),

          // Card Jadwal 1
          _buildJadwalItemCard(
            code: 'IF3201',
            title: 'Pemrograman Mobile',
            time: '08:00 - 10:30 WIB',
            room: 'Lab Multimedia 302',
            lecturer: 'Dr. Budi Santoso, M.Kom',
            tag: 'Sesi Aktif Sekarang',
            tagColor: AppColors.badgeGreen,
            canScan: true,
          ),
          const SizedBox(height: 12),

          // Card Jadwal 2
          _buildJadwalItemCard(
            code: 'IF3204',
            title: 'Basis Data Terdistribusi',
            time: '13:00 - 15:30 WIB',
            room: 'Ruang Teori R.401',
            lecturer: 'Prof. Handoko, Ph.D',
            tag: 'Mendatang',
            tagColor: AppColors.textGrey,
            canScan: false,
          ),
          const SizedBox(height: 20),

          // Event & Agenda Kampus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Event & Agenda Kampus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text('Lihat Semua', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('AI & Cloud Architecture Summit 2026', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('Kamis, 17 Okt • Auditorium Rektorat', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket QR Event Dibuka')));
                  },
                  child: const Text('Tiket QR', style: TextStyle(fontSize: 11, color: Colors.white)),
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
  // TAB 2: RIWAYAT KEHADIRAN
  // ==========================================
  Widget _buildTabRiwayat() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Presensi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Log kehadiran tersinkronisasi SIAKAD & GPS', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 16),

          _buildHistoryItem('Pemrograman Mobile', '16 Okt 2026 • 08:05 WIB', 'Lab 301', 'Hadir Tepat Waktu', AppColors.badgeGreen),
          const SizedBox(height: 10),
          _buildHistoryItem('Basis Data Terdistribusi', '14 Okt 2026 • 13:00 WIB', 'Ruang 401', 'Hadir Tepat Waktu', AppColors.badgeGreen),
          const SizedBox(height: 10),
          _buildHistoryItem('Kalkulus Lanjut', '12 Okt 2026 • 10:00 WIB', 'Ruang 202', 'Izin Sakit (Disetujui)', AppColors.badgeOrange),
          const SizedBox(height: 10),
          _buildHistoryItem('Pemrograman Berorientasi Objek', '08 Okt 2026 • 08:00 WIB', 'Lab 205', 'Alpa (Di Luar Radius)', AppColors.badgeRed),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: PROFIL & TOLERANSI ALPA (Figma Screen 2)
  // ==========================================
  Widget _buildTabProfil(String name, String nim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Profil
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

          // 3 Kotak Statistik (Semester, IPK, SKS)
          Row(
            children: [
              _buildProfileStatBox('Semester', '5'),
              const SizedBox(width: 10),
              _buildProfileStatBox('IPK Kumulatif', '3.84'),
              const SizedBox(width: 10),
              _buildProfileStatBox('Total SKS', '88 SKS'),
            ],
          ),
          const SizedBox(height: 20),

          // Regulasi Toleransi Alpa (Figma Card Kritis)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Status & Batas Toleransi Alpa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Icon(Icons.info_outline, size: 16, color: AppColors.textGrey),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Maksimal toleransi alpa per matkul adalah 3 kali sebelum pencekalan UAS.', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
          const SizedBox(height: 12),

          // Matkul 1: Kritis (Alpa 2/3 - Merah)
          _buildAlpaCard(
            courseTitle: 'Kalkulus Lanjut',
            sks: '3 SKS • Semester Genap',
            alpaCount: '2 / 3 Alpa',
            statusNote: 'BAHAYA: Sisa 1 kali alpa sebelum pencekalan ujian akhir!',
            isCritical: true,
            badgeColor: AppColors.badgeRed,
          ),
          const SizedBox(height: 10),

          // Matkul 2: Waspada (Alpa 1/3 - Oranye)
          _buildAlpaCard(
            courseTitle: 'Pemrograman Berorientasi Objek',
            sks: '3 SKS • Semester Genap',
            alpaCount: '1 / 3 Alpa',
            statusNote: 'Perhatian: Kuota tersisa 2 kali kehadiran alpa.',
            isCritical: false,
            badgeColor: AppColors.badgeOrange,
          ),
          const SizedBox(height: 10),

          // Matkul 3: Aman (Alpa 0/3 - Hijau)
          _buildAlpaCard(
            courseTitle: 'Pemrograman Mobile',
            sks: '3 SKS • Semester Genap',
            alpaCount: '0 / 3 Alpa',
            statusNote: 'Aman: Tingkat kehadiran sempurna 100%.',
            isCritical: false,
            badgeColor: AppColors.badgeGreen,
          ),
          const SizedBox(height: 24),

          // Tombol Keluar / Logout
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
        ],
      ),
    );
  }

  // ==========================================
  // MODAL BOTTOM SHEET: DUAL-GUARD SCANNER (Figma Modal)
  // ==========================================
  void _showDualGuardScannerModal(BuildContext context) {
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
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
                      child: const Row(
                        children: [
                          Icon(Icons.gps_fixed, size: 12, color: AppColors.badgeGreen),
                          SizedBox(width: 4),
                          Text('GPS Terkunci: Lab 301', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.badgeGreen)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Viewfinder Mockup
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 2.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code_scanner_rounded, size: 80, color: Colors.white54),
                      SizedBox(height: 10),
                      Text('Posisikan QR Dosen di dalam bingkai', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Hasil Verifikasi Sukses (Figma White Card Bottom)
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
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: AppColors.badgeGreen, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text('Presensi Berhasil Dicatat!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const Text('Terkonfirmasi melalui Geofence & Dynamic Token', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Pemrograman Mobile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('08:14 WIB • Hadir', style: TextStyle(fontSize: 12, color: AppColors.badgeGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup & Kembali ke Beranda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedJadwalFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedJadwalFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textGrey)),
      ),
    );
  }

  Widget _buildDayPill(String day, int date) {
    final isSelected = _selectedDay == date;
    return InkWell(
      onTap: () => setState(() => _selectedDay = date),
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