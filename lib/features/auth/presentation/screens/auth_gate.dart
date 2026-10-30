import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import 'login_screen.dart';
import 'role_router.dart';

/// Layar awal: memulihkan sesi dari secure storage (auto-login).
/// Jika sesi tidak ada, tampilkan login. Jika ada, ambil profil terbaru dari
/// database; bila jaringan gagal, pakai data yang tersimpan di perangkat.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<UserModel?> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _restoreFuture = _restoreSession();
  }

  Future<UserModel?> _restoreSession() async {
    final session = await SessionService.getSession();
    final userId = session['userId'];
    if (userId == null || userId.isEmpty) return null;

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('id, identifier_id, name, role, ipk, sks_total')
          .eq('id', userId)
          .maybeSingle();

      if (row == null) {
        // Akun sudah dihapus admin -> sesi tidak berlaku lagi.
        await SessionService.clearSession();
        return null;
      }
      return UserModel.fromJson(row);
    } catch (_) {
      // Offline / gangguan jaringan: pakai data sesi lokal.
      final role = session['role'];
      final name = session['name'];
      if (role == null || name == null) return null;
      return UserModel(id: userId, identifierId: '-', name: name, role: role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _restoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return dashboardForUser(user);
      },
    );
  }
}
