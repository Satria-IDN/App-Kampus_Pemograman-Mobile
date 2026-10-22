import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Role aktif: 'mahasiswa', 'dosen', atau 'admin'
  String _selectedRole = 'mahasiswa';
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID/NIM dan Kata Sandi wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Validasi kredensial sekaligus mencocokkan perannya di Supabase
      final response = await supabase
          .from('profiles')
          .select()
          .eq('identifier_id', identifier)
          .eq('password', password)
          .eq('role', _selectedRole)
          .maybeSingle();

      if (response == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.badgeRed,
            content: Text(
              _selectedRole == 'admin'
                  ? 'Akses Ditolak: Kredensial tidak terdaftar sebagai Administrator institusi!'
                  : 'Kredensial salah atau peran tidak sesuai.',
            ),
          ),
        );
        return;
      }

      // 1. Simpan UUID, peran, dan nama ke FlutterSecureStorage via SessionService
      await SessionService.saveSession(
        userId: response['id'] as String, // Menyimpan UUID agar tidak bernilai NULL saat presensi
        role: response['role'] as String? ?? _selectedRole,
        name: (response['name'] ?? response['full_name'] ?? 'Pengguna') as String,
      );

      // 2. Tampilkan pesan selamat datang
      if (!mounted) return;
      final displayName = response['name'] ?? response['full_name'] ?? 'Pengguna';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.badgeGreen,
          content: Text('Selamat datang, $displayName!'),
        ),
      );

      // 3. Navigasi ke halaman sesuai role
      if (_selectedRole == 'mahasiswa') {
        Navigator.pushReplacementNamed(context, '/dashboard-student');
      } else if (_selectedRole == 'dosen') {
        Navigator.pushReplacementNamed(context, '/dashboard-lecturer');
      } else {
        Navigator.pushReplacementNamed(context, '/admin-panel');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.badgeRed,
          content: Text('Terjadi kesalahan sistem: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo Aplikasi CampusPulse
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CampusPulse',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Satu akses untuk seluruh ekosistem kehidupan kampus',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),

                // 2. Segmented Pill Switcher (Mahasiswa | Dosen | Admin)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _buildRoleTab('mahasiswa', 'Mahasiswa', Icons.school_outlined),
                      _buildRoleTab('dosen', 'Dosen', Icons.co_present_outlined),
                      _buildRoleTab('admin', 'Admin', Icons.admin_panel_settings_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Kartu Form Login Putih
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Input 1 (Label & Badge Contoh)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedRole == 'admin'
                                ? 'USERNAME PEGAWAI'
                                : (_selectedRole == 'dosen' ? 'NIDN DOSEN' : 'NIM / NIDN'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedRole == 'admin'
                                  ? 'Contoh: ADM001'
                                  : (_selectedRole == 'dosen' ? 'Contoh: 8041' : 'Contoh: 20240801048'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _identifierController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                          prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textGrey),
                          hintText: _selectedRole == 'admin'
                              ? 'Masukkan ID Administrator'
                              : (_selectedRole == 'dosen'
                              ? 'Masukkan Nomor Induk Dosen'
                              : 'Masukkan Nomor Induk Mahasiswa'),
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Input 2: Kata Sandi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kata Sandi Akun',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'Lupa Kata Sandi?',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textGrey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textGrey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          hintText: '••••••••••••',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Info Geofence & Enkripsi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.circle, color: AppColors.badgeGreen, size: 8),
                              SizedBox(width: 6),
                              Text('Geofence Siap', style: TextStyle(fontSize: 11, color: AppColors.textDark)),
                            ],
                          ),
                          Row(
                            children: const [
                              Icon(Icons.shield_outlined, color: AppColors.textGrey, size: 14),
                              SizedBox(width: 4),
                              Text('Enkripsi RSA-2048', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tombol Masuk Lebar Penuh
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'MASUK KE SISTEM',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Tombol SSO: Hanya ditampilkan untuk Mahasiswa & Dosen (Admin disembunyikan)
                if (_selectedRole != 'admin') ...[
                  const SizedBox(height: 20),
                  const Text(
                    'ATAU VERIFIKASI VIA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SSO Kampus dipilih')),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 28),
                          SizedBox(width: 4),
                          Text(
                            'Masuk dengan SSO Google Kampus',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // 5. Footer Institusi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.textGrey),
                    SizedBox(width: 6),
                    Text('Terintegrasi SIAKAD v1.0', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pusat Teknologi Informasi • Universitas Esa Unggul',
                  style: TextStyle(fontSize: 10, color: Color(0xFFA0AEC0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _identifierController.clear();
            _passwordController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textGrey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}