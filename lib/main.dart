import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase[cite: 1, 2]
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestDatabaseScreen(),
    );
  }
}

class TestDatabaseScreen extends StatefulWidget {
  const TestDatabaseScreen({super.key});

  @override
  State<TestDatabaseScreen> createState() => _TestDatabaseScreenState();
}

class _TestDatabaseScreenState extends State<TestDatabaseScreen> {
  // Query Supabase untuk mengambil 3 mata kuliah contoh[cite: 1, 2]
  final Future<List<Map<String, dynamic>>> _coursesFuture =
  Supabase.instance.client.from('courses').select('course_code, course_name, sks');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusPulse - Uji Minggu 1'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Koneksi Gagal: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(child: Text('Tidak ada data mata kuliah ditemukan.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = courses[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text('${item['sks']}'),
                ),
                title: Text(item['course_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Kode Matkul: ${item['course_code']}'),
              );
            },
          );
        },
      ),
    );
  }
}