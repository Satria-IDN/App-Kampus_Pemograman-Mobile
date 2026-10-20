import 'package:flutter/material.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/geofence_service.dart';

class AdminPanelScreen extends StatefulWidget {
  final UserModel? user;
  const AdminPanelScreen({super.key, this.user});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentNavIndex = 0; // 0: Beranda/GPS, 1: Matkul, 2: Log Audit, 3: Profil
  String _selectedMasterTab = 'Titik GPS'; // Titik GPS, Matkul, Kelola Akun
  int _selectedRadius = 50; // 15, 50, 150
  String _activeRoomName = 'Lab Komputer 301';
  String _activeRoomDetail = 'Gedung B, Lantai 3 • Kampus Utama';

  final TextEditingController _latController = TextEditingController(text: '-6.188224');
  final TextEditingController _lngController = TextEditingController(text: '106.824550');

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // FAB Tengah Aktif: Membuka Modal Tambah Ruang / Titik GPS Baru
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () => _showAddRoomModal(context),
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 26),
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
              _buildNavItem(icon: Icons.auto_stories_rounded, label: 'Matkul', index: 1),
              const SizedBox(width: 48), // Ruang lekukan FAB
              _buildNavItem(icon: Icons.history_rounded, label: 'Log Audit', index: 2),
              _buildNavItem(icon: Icons.person_outline_rounded, label: 'Profil', index: 3),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildTabBerandaAdmin(),
            _buildTabMasterMatkul(),
            _buildTabLogAudit(),
            _buildTabProfilAdmin(),
          ],
        ),
      ),
    );
  }

// ==========================================
  // TAB 0: BERANDA & KONFIGURASI GEOFENCING (FIGMA SCREEN)
  // ==========================================
  Widget _buildTabBerandaAdmin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(),
          const SizedBox(height: 14),

          // Judul Header Panel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ADMIN PANEL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pusat Konfigurasi Master Data SIAKAD',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Super Admin',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metrik Statistik Master Data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildStatTile(count: '142', label: 'Total Matkul')),
                Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildStatTile(count: '38', label: 'Ruang Terdaftar')),
                Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
                Expanded(
                  child: _buildStatTile(
                    count: '100%',
                    label: 'Geofence Aktif',
                    accentColor: AppColors.badgeGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Pilihan Submenu Master
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildMasterTab('Titik GPS', Icons.my_location_rounded, () {}),
                _buildMasterTab('Matkul', Icons.auto_stories_rounded, () => setState(() => _currentNavIndex = 1)),
                _buildMasterTab('Kelola Akun', Icons.people_alt_rounded, () => _showKelolaAkunDialog()),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kartu Konfigurasi Geofencing Interaktif
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TARGET RUANG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Aktif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.badgeGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pemilih Ruangan Dropdown
                InkWell(
                  onTap: () => _showRoomSelectorSheet(),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeRoomName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
                    ],
                  ),
                ),
                Text(_activeRoomDetail, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(height: 14),

                // Mockup Peta Geofence Interaktif
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD6E4FF)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _selectedRadius == 15 ? 65 : (_selectedRadius == 50 ? 100 : 130),
                        height: _selectedRadius == 15 ? 65 : (_selectedRadius == 50 ? 100 : 130),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 26),
                          const SizedBox(height: 2),
                          Text(
                            'Radius $_selectedRadius Meter',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Peta Geofence Kampus', style: TextStyle(fontSize: 9, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Pilihan Radius Cepat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Batas Radius Geofence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    Text('$_selectedRadius Meter', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRadiusChip(15, 'Min (15m)'),
                    const SizedBox(width: 8),
                    _buildRadiusChip(50, '50m (Standar)'),
                    const SizedBox(width: 8),
                    _buildRadiusChip(150, 'Max (150m)'),
                  ],
                ),
                const SizedBox(height: 14),

                // Kolom Koordinat
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Latitude', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _latController,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Longitude', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _lngController,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tombol Kuncikan GPS Saat Ini (Riil & Aman Asinkron)
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final error = await GeofenceService.checkAndRequestPermission();
                      if (error != null) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(backgroundColor: AppColors.badgeRed, content: Text(error)),
                        );
                        return;
                      }

                      messenger.showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 1),
                          content: Text('Mengunci sinyal satelit GPS...'),
                        ),
                      );

                      try {
                        final pos = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                        );

                        if (!mounted) return;
                        setState(() {
                          _latController.text = pos.latitude.toStringAsFixed(6);
                          _lngController.text = pos.longitude.toStringAsFixed(6);
                        });

                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.badgeGreen,
                            content: Text('Lokasi terkunci! Akurasi: ±${pos.accuracy.toStringAsFixed(1)}m'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.badgeRed,
                            content: Text('Gagal membaca koordinat GPS perangkat.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Kuncikan Lokasi Saya Saat Ini',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Daftar Titik Ruangan (38)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daftar Titik Ruangan (38)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              TextButton(
                onPressed: () => _showRoomSelectorSheet(),
                child: const Text('Kelola Semua', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          _buildRoomTile(
            roomName: 'Lab 301',
            detail: 'Gedung B Lt. 3 • 50m Radius',
            status: 'Aktif',
            statusColor: AppColors.badgeGreen,
            statusBg: const Color(0xFFDCFCE7),
            onTap: () {
              setState(() {
                _activeRoomName = 'Lab Komputer 301';
                _activeRoomDetail = 'Gedung B, Lantai 3 • Kampus Utama';
                _selectedRadius = 50;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildRoomTile(
            roomName: 'Ruang Teori 204',
            detail: 'Gedung A Lt. 2 • 45m Radius',
            status: 'Aktif',
            statusColor: AppColors.badgeGreen,
            statusBg: const Color(0xFFDCFCE7),
            onTap: () {
              setState(() {
                _activeRoomName = 'Ruang Teori 204';
                _activeRoomDetail = 'Gedung A, Lantai 2 • Kampus Utama';
                _selectedRadius = 50;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildRoomTile(
            roomName: 'Auditorium Rektorat',
            detail: 'Gedung Pusat • 75m Radius',
            status: 'Khusus Event',
            statusColor: AppColors.badgeOrange,
            statusBg: const Color(0xFFFFFBEB),
            onTap: () {
              setState(() {
                _activeRoomName = 'Auditorium Rektorat';
                _activeRoomDetail = 'Gedung Rektorat Lt. 2 • Kampus Pusat';
                _selectedRadius = 150;
              });
            },
          ),
          const SizedBox(height: 18),

          // Tombol Simpan & Sinkronisasi SIAKAD
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.badgeGreen,
                    content: Text('Konfigurasi Geofencing Berhasil Disinkronisasi ke SIAKAD & Database!'),
                  ),
                );
              },
              icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
              label: const Text('Simpan & Sinkronisasi SIAKAD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Perubahan langsung diterapkan ke semua presensi mahasiswa', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  // ==========================================
  // TAB 1: MASTER DATA MATKUL
  // ==========================================
  Widget _buildTabMasterMatkul() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Master Kurikulum & Matkul', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                onPressed: () => _showAddCourseDialog(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Total 142 mata kuliah aktif terintegrasi SIAKAD', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 14),

          _buildCourseMasterTile('IF3201', 'Pemrograman Mobile', '3 SKS • Semester 5', 'Prof. Handoko, M.Kom', 'Lab 301'),
          const SizedBox(height: 10),
          _buildCourseMasterTile('IF3204', 'Basis Data Terdistribusi', '3 SKS • Semester 5', 'Prof. Handoko, Ph.D', 'Ruang 401'),
          const SizedBox(height: 10),
          _buildCourseMasterTile('IF2102', 'Algoritma & Struktur Data', '3 SKS • Semester 3', 'Dr. Budi Santoso, M.Kom', 'Ruang 104'),
          const SizedBox(height: 10),
          _buildCourseMasterTile('IF3105', 'Kecerdasan Buatan & ML', '3 SKS • Semester 5', 'Dr. Rina Maharani, S.T.', 'Auditorium'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LOG AUDIT & SINKRONISASI
  // ==========================================
  Widget _buildTabLogAudit() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Audit & Keamanan Sistem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Catatan perubahan geofence, presensi darurat, dan sesi', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 16),

          _buildAuditTile('Sinkronisasi Geofence', 'Radius Lab 301 diperbarui ke 50m oleh Super Admin', '16 Okt 2026 • 00:15 WIB', AppColors.badgeGreen),
          const SizedBox(height: 10),
          _buildAuditTile('Presensi Dosen Dibuka', 'Sesi Pemrograman Mobile (IF-4A) dimulai di Lab 301', '15 Okt 2026 • 08:00 WIB', AppColors.primary),
          const SizedBox(height: 10),
          _buildAuditTile('Anomali Geofence Terdeteksi', 'Percobaan presensi di luar radius (NIM 20240801048)', '15 Okt 2026 • 08:04 WIB', AppColors.badgeRed),
          const SizedBox(height: 10),
          _buildAuditTile('Kalibrasi Koordinat', 'GPS Gedung B diperbarui (+0.000012 lat)', '14 Okt 2026 • 16:20 WIB', AppColors.badgeOrange),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: PROFIL SUPER ADMIN & PENGATURAN
  // ==========================================
  Widget _buildTabProfilAdmin() {
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
                  child: Icon(Icons.shield_rounded, color: AppColors.primary, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Super Administrator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('ID: ADM-2024 • Hak Akses Penuh', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      SizedBox(height: 2),
                      Text('Pusat Teknologi Informasi Kampus', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('Kontrol Server & Keamanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_done_rounded, color: AppColors.badgeGreen),
                  title: const Text('Status Supabase & SIAKAD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tersambung (Latensi 28ms)', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  trailing: const Icon(Icons.check_circle_rounded, color: AppColors.badgeGreen, size: 18),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                  title: const Text('Kunci Enkripsi Master RSA-2048', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Valid hingga 2028', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Logout Admin
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
              label: const Text('Keluar dari Panel Admin (Logout)', style: TextStyle(color: AppColors.badgeRed, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL BOTTOM SHEET: TAMBAH RUANG BARU (FAB)
  // ==========================================
  void _showAddRoomModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '50');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Tambah Titik Ruang & Geofence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Ruangan (Contoh: Lab Jaringan 201)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radiusCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Radius Geofence (Meter)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.badgeGreen,
                        content: Text('Ruang ${nameCtrl.text.isEmpty ? "Baru" : nameCtrl.text} berhasil ditambahkan!'),
                      ),
                    );
                  },
                  child: const Text('Simpan Ruang Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modal Pemilih Ruangan Aktif
  void _showRoomSelectorSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Target Ruangan Geofence', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRoomOptionTile('Lab Komputer 301', 'Gedung B, Lt. 3 • 50m Radius', '-6.188224', '106.824550', 50),
            _buildRoomOptionTile('Ruang Teori 204', 'Gedung A, Lt. 2 • 45m Radius', '-6.188150', '106.824600', 50),
            _buildRoomOptionTile('Auditorium Rektorat', 'Gedung Pusat, Lt. 2 • 75m Radius', '-6.188400', '106.824300', 150),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomOptionTile(String name, String detail, String lat, String lng, int rad) {
    return ListTile(
      leading: const Icon(Icons.room_rounded, color: AppColors.primary),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      onTap: () {
        setState(() {
          _activeRoomName = name;
          _activeRoomDetail = detail;
          _latController.text = lat;
          _lngController.text = lng;
          _selectedRadius = rad;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Tambah Mata Kuliah SIAKAD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Koneksi sinkronisasi SIAKAD siap menerima kurikulum baru.', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form pembuatan kurikulum dibuka')));
            },
            child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showKelolaAkunDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Kelola Akun Kampus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Manajemen hak akses 3-Role (Mahasiswa, Dosen, Administrator) terhubung ke Supabase.', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
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
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
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
              child: Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile({required String count, required String label, Color accentColor = AppColors.textDark}) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMasterTab(String title, IconData icon, VoidCallback onTap) {
    final isSelected = _selectedMasterTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMasterTab = title);
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.primary),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusChip(int radius, String label) {
    final isSelected = _selectedRadius == radius;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRadius = radius),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTile({
    required String roomName,
    required String detail,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                  Text(roomName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text(detail, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseMasterTile(String code, String name, String sks, String lecturer, String room) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text('$sks • $lecturer', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: Text(room, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTile(String title, String detail, String time, Color tagColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
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
}