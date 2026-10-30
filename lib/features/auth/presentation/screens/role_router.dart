import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../../dashboard/presentation/screens/admin_panel_screen.dart';
import '../../../dashboard/presentation/screens/lecturer_dashboard_screen.dart';
import '../../../dashboard/presentation/screens/student_dashboard_screen.dart';

/// Memilih dashboard sesuai role dan meneruskan data user ke layar tujuan.
Widget dashboardForUser(UserModel user) {
  switch (user.role) {
    case 'admin':
      return AdminPanelScreen(user: user);
    case 'dosen':
      return LecturerDashboardScreen(user: user);
    case 'mahasiswa':
      return StudentDashboardScreen(user: user);
    default:
      return const Scaffold(
        body: Center(child: Text('Peran akun tidak terdefinisi di sistem.')),
      );
  }
}
