import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../rooms/presentation/widgets/room_management_panel.dart';

class AdminPanelScreen extends StatefulWidget {
  final UserModel? user;
  const AdminPanelScreen({super.key, this.user});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _supabase = Supabase.instance.client;

  int _currentNavIndex = 0; // 0: Beranda/GPS, 1: Matkul, 2: Log Audit, 3: Profil
  String _selectedMasterTab = 'Titik GPS';


  // Kunci untuk membuka form ruangan dari tombol + di bawah
  final GlobalKey<RoomManagementPanelState> _roomPanelKey = GlobalKey<RoomManagementPanelState>();

  // State Data Pengguna dari Supabase
  List<Map<String, dynamic>> _userProfiles = [];
  bool _isLoadingProfiles = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfiles();
  }

  // Mengambil daftar profil dari Supabase
  Future<void> _fetchUserProfiles() async {
    setState(() => _isLoadingProfiles = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _userProfiles = List<Map<String, dynamic>>.from(response);
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () {
          setState(() => _currentNavIndex = 0);
          _roomPanelKey.currentState?.openEditor();
        },
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
              const SizedBox(width: 48),
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
  // TAB 0: BERANDA & KONFIGURASI GEOFENCING
  // ==========================================
  Widget _buildTabBerandaAdmin() {
    final mhsCount = _userProfiles.where((u) => u['role'] == 'mahasiswa').length;
    final dosenCount = _userProfiles.where((u) => u['role'] == 'dosen').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(),
          const SizedBox(height: 14),

          // Header Panel
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
                    'Pusat Konfigurasi Master Data',
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
                Expanded(child: _buildStatTile(count: '$mhsCount', label: 'Mahasiswa')),
                Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildStatTile(count: '$dosenCount', label: 'Dosen')),
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

          // Submenu Master Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildMasterTab('Titik GPS', Icons.my_location_rounded, () {
                  setState(() => _selectedMasterTab = 'Titik GPS');
                }),
                _buildMasterTab('Matkul', Icons.auto_stories_rounded, () {
                  setState(() {
                    _selectedMasterTab = 'Matkul';
                    _currentNavIndex = 1;
                  });
                }),
                _buildMasterTab('Kelola Akun', Icons.people_alt_rounded, () {
                  setState(() => _selectedMasterTab = 'Kelola Akun');
                  _showKelolaAkunSheet();
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kelola titik GPS ruangan & penetapan ruangan per mata kuliah (data nyata)
          RoomManagementPanel(key: _roomPanelKey),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL KELOLA AKUN TERPADU & AMAN (ROLE FILTER)
  // ==========================================
  void _showKelolaAkunSheet() {
    String selectedFilter = 'semua'; // 'semua', 'mahasiswa', 'dosen', 'admin'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filteredUsers = _userProfiles.where((u) {
              if (selectedFilter == 'semua') return true;
              return (u['role']?.toString().toLowerCase()) == selectedFilter;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Modal & Tombol Tambah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Kelola Akun Kampus',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manajemen hak akses & kredensial civitas akademika',
                            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showAddUserDialog(onAdded: () {
                          _fetchUserProfiles();
                          setSheetState(() {});
                        }),
                        icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                        label: const Text('Tambah Akun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tab Filter Segmented
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('Semua', 'semua', selectedFilter, () => setSheetState(() => selectedFilter = 'semua')),
                        const SizedBox(width: 8),
                        _buildFilterPill('Mahasiswa', 'mahasiswa', selectedFilter, () => setSheetState(() => selectedFilter = 'mahasiswa')),
                        const SizedBox(width: 8),
                        _buildFilterPill('Dosen', 'dosen', selectedFilter, () => setSheetState(() => selectedFilter = 'dosen')),
                        const SizedBox(width: 8),
                        _buildFilterPill('Admin', 'admin', selectedFilter, () => setSheetState(() => selectedFilter = 'admin')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Daftar Kartu Pengguna
                  Expanded(
                    child: _isLoadingProfiles
                        ? const Center(child: CircularProgressIndicator())
                        : filteredUsers.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_search_rounded, size: 44, color: AppColors.textGrey),
                          SizedBox(height: 8),
                          Text('Tidak ada pengguna pada kategori ini', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                        ],
                      ),
                    )
                        : ListView.separated(
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final user = filteredUsers[idx];
                        final role = (user['role'] ?? '-').toString().toLowerCase();
                        final isMhs = role == 'mahasiswa';
                        final isDosen = role == 'dosen';

                        final accentColor = isMhs
                            ? AppColors.primary
                            : (isDosen ? const Color(0xFF16A34A) : const Color(0xFF7C3AED));
                        final bgColor = isMhs
                            ? const Color(0xFFEEF2FF)
                            : (isDosen ? const Color(0xFFDCFCE7) : const Color(0xFFEDE9FE));
                        final roleIcon = isMhs
                            ? Icons.school_rounded
                            : (isDosen ? Icons.co_present_rounded : Icons.admin_panel_settings_rounded);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 1. Avatar Kiri
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: bgColor,
                                child: Icon(roleIcon, color: accentColor, size: 20),
                              ),
                              const SizedBox(width: 12),

                              // 2. Info Tengah (Tanpa Password Plain)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 3),
                                    if (isMhs)
                                      Text(
                                        'NIM: ${user['identifier_id']} • IPK: ${user['ipk'] ?? '0.00'} • SKS: ${user['sks_total'] ?? 0}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                                      )
                                    else if (isDosen)
                                      Text(
                                        'NIDN: ${user['identifier_id']} • Dosen Fakultas Ilmu Komputer',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                                      )
                                    else
                                      Text(
                                        'ID: ${user['identifier_id']} • Hak Akses Administrator',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                                      ),
                                  ],
                                ),
                              ),

                              // 3. Badge Role
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),

                              // 4. Menu Aksi Titik Tiga
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textGrey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (val) {
                                  if (val == 'reset') {
                                    _showResetPasswordDialog(user);
                                  } else if (val == 'delete') {
                                    _showDeleteUserDialog(user, onDeleted: () {
                                      _fetchUserProfiles();
                                      setSheetState(() {});
                                    });
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'reset',
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Reset Kata Sandi', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.badgeRed),
                                        SizedBox(width: 8),
                                        Text('Hapus Akun', style: TextStyle(fontSize: 12, color: AppColors.badgeRed)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget Tombol Filter Pill
  Widget _buildFilterPill(String label, String value, String currentSelected, VoidCallback onTap) {
    final isSelected = value == currentSelected;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DIALOG RESET KATA SANDI (AMAN & HASH OTOMATIS)
  // ==========================================
  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final newPassCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Reset Kata Sandi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setel kata sandi baru untuk ${user['name']} (${user['identifier_id']}):',
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      hintText: 'Masukkan sandi sementara',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      final randomPass = 'CP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      newPassCtrl.text = randomPass;
                    },
                    icon: const Icon(Icons.shuffle_rounded, size: 14),
                    label: const Text('Generate Sandi Acak', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    if (newPassCtrl.text.trim().isEmpty) return;
                    setDialogState(() => isSubmitting = true);
                    try {
                      // Update langsung di Supabase, Trigger PostgreSQL otomatis menghash password
                      await _supabase
                          .from('profiles')
                          .update({'password': newPassCtrl.text.trim()})
                          .eq('id', user['id']);

                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.badgeGreen,
                            content: Text('Kata sandi untuk ${user['name']} berhasil diperbarui!'),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (dialogCtx.mounted) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          SnackBar(backgroundColor: AppColors.badgeRed, content: Text('Gagal reset sandi: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan Sandi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // DIALOG HAPUS AKUN PENGGUNA
  // ==========================================
  void _showDeleteUserDialog(Map<String, dynamic> user, {required VoidCallback onDeleted}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun Pengguna', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun ${user['name']} (${user['identifier_id']})? Tindakan ini bersifat permanen.',
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.badgeRed),
            onPressed: () async {
              try {
                await _supabase.from('profiles').delete().eq('id', user['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                onDeleted();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppColors.badgeGreen, content: Text('Akun berhasil dihapus.')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppColors.badgeRed, content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus Akun', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOG TAMBAH PENGGUNA BARU KE SUPABASE
  // ==========================================
  void _showAddUserDialog({required VoidCallback onAdded}) {
    final formKey = GlobalKey<FormState>();
    final identifierCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final ipkCtrl = TextEditingController(text: '3.50');
    final sksCtrl = TextEditingController(text: '0');

    String selectedRole = 'mahasiswa';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Tambah Pengguna Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Peran Akun',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'mahasiswa', child: Text('Mahasiswa')),
                            DropdownMenuItem(value: 'dosen', child: Text('Dosen')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: identifierCtrl,
                          decoration: InputDecoration(
                            labelText: selectedRole == 'mahasiswa' ? 'NIM Mahasiswa' : 'NIDN/NIP Dosen',
                            hintText: selectedRole == 'mahasiswa' ? 'Contoh: 20240801048' : 'Contoh: 8041',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap Beserta Gelar',
                            hintText: 'Contoh: Dr. Budi Santoso, M.Kom.',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi Login',
                            hintText: 'Masukkan kata sandi awal',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                        if (selectedRole == 'mahasiswa') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: ipkCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'IPK Awal',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: sksCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Total SKS',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textGrey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSubmitting = true);

                    try {
                      final insertPayload = <String, dynamic>{
                        'identifier_id': identifierCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'password': passwordCtrl.text.trim(), // Otomatis di-hash oleh Trigger Supabase
                        'role': selectedRole,
                      };

                      if (selectedRole == 'mahasiswa') {
                        insertPayload['ipk'] = double.tryParse(ipkCtrl.text.trim()) ?? 0.0;
                        insertPayload['sks_total'] = int.tryParse(sksCtrl.text.trim()) ?? 0;
                      }

                      // Simpan langsung ke tabel public.profiles di Supabase
                      await _supabase.from('profiles').insert(insertPayload);

                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      onAdded();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.badgeGreen,
                            content: Text('Akun baru berhasil ditambahkan dan diamankan!'),
                          ),
                        );
                      }
                    } catch (err) {
                      setDialogState(() => isSubmitting = false);
                      if (dialogCtx.mounted) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          SnackBar(backgroundColor: AppColors.badgeRed, content: Text('Gagal: $err')),
                        );
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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

          _buildAuditTile('Sinkronisasi Geofence', 'Radius Lab 301 diperbarui ke 50m oleh Super Admin', '26 Okt 2026 • 10:15 WIB', AppColors.badgeGreen),
          const SizedBox(height: 10),
          _buildAuditTile('Presensi Dosen Dibuka', 'Sesi Pemrograman Mobile dimulai di Lab 301', '26 Okt 2026 • 08:00 WIB', AppColors.primary),
          const SizedBox(height: 10),
          _buildAuditTile('Anomali Geofence Terdeteksi', 'Percobaan presensi di luar radius (NIM 20240801048)', '26 Okt 2026 • 08:04 WIB', AppColors.badgeRed),
          const SizedBox(height: 10),
          _buildAuditTile('Kalibrasi Koordinat', 'GPS Gedung B diperbarui (+0.000012 lat)', '25 Okt 2026 • 16:20 WIB', AppColors.badgeOrange),
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
                      Text('ID: ADM001 • Hak Akses Penuh', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
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
                  subtitle: const Text('Tersambung (Latensi 24ms)', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
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
        onTap: onTap,
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
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}