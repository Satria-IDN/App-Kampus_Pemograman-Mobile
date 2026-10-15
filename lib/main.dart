import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/student_dashboard_screen.dart';
import 'features/dashboard/presentation/screens/lecturer_dashboard_screen.dart';
import 'features/dashboard/presentation/screens/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConstants.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusPulse',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard-student': (context) => const StudentDashboardScreen(),
        '/dashboard-lecturer': (context) => const LecturerDashboardScreen(),
        '/admin-panel': (context) => const AdminPanelScreen(),
      },
    );
  }
}