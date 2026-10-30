import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/qr_token_service.dart';

class LecturerQrProjectorScreen extends StatefulWidget {
  final String sessionId;
  final String courseName;
  final String roomName;

  const LecturerQrProjectorScreen({
    super.key,
    required this.sessionId,
    this.courseName = 'Pemrograman Mobile',
    this.roomName = 'Lab Komputer 301',
  });

  @override
  State<LecturerQrProjectorScreen> createState() => _LecturerQrProjectorScreenState();
}

class _LecturerQrProjectorScreenState extends State<LecturerQrProjectorScreen> {
  final _supabase = Supabase.instance.client;

  String _currentQrPayload = '';
  int _secondsLeft = 20;
  Timer? _qrRefreshTimer;
  RealtimeChannel? _attendanceChannel;

  List<Map<String, dynamic>> _attendees = [];
  bool _isLoadingInitialData = true;

  @override
  void initState() {
    super.initState();
    _fetchExistingAttendance();
    _startDynamicQrCycle();
    _subscribeToLiveAttendance();
  }

  @override
  void dispose() {
    _qrRefreshTimer?.cancel();
    if (_attendanceChannel != null) {
      _supabase.removeChannel(_attendanceChannel!);
    }
    super.dispose();
  }

  // 1. Ambil data mahasiswa yang sudah hadir sebelum proyektor dibuka
  Future<void> _fetchExistingAttendance() async {
    try {
      final data = await _supabase
          .from('attendance_logs')
          .select('id, verified_distance, scanned_at, profiles(id, name, identifier_id)')
          .eq('session_id', widget.sessionId)
          .order('scanned_at', ascending: false);

      if (mounted) {
        setState(() {
          _attendees = List<Map<String, dynamic>>.from(data);
          _isLoadingInitialData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInitialData = false);
    }
  }

  // 2. Putar token QR dinamis setiap 20 detik
  void _startDynamicQrCycle() {
    _generateNewQrToken();

    _qrRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 20;
          _generateNewQrToken();
        }
      });
    });
  }

  void _generateNewQrToken() {
    // Panggil method generateSessionPayload langsung dari QrTokenService
    final payload = QrTokenService.generateSessionPayload(widget.sessionId);
    setState(() {
      _currentQrPayload = payload;
    });
  }

  // 3. Dengarkan event INSERT baru secara realtime dari Supabase
  void _subscribeToLiveAttendance() {
    _attendanceChannel = _supabase
        .channel('public:attendance_logs:session_${widget.sessionId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'attendance_logs',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: widget.sessionId,
      ),
      callback: (payload) async {
        final newRecord = payload.newRecord;
        final studentId = newRecord['student_id'];

        // Tarik identitas profil mahasiswa yang baru masuk
        final studentProfile = await _supabase
            .from('profiles')
            .select('id, name, identifier_id')
            .eq('id', studentId)
            .maybeSingle();

        if (!mounted) return;
        setState(() {
          _attendees.insert(0, {
            'id': newRecord['id'],
            'verified_distance': newRecord['verified_distance'],
            'scanned_at': newRecord['scanned_at'],
            'profiles': studentProfile ?? {'name': 'Mahasiswa', 'identifier_id': '-'},
          });
        });
      },
    )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Latar gelap elegan untuk proyektor
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${widget.roomName} • Sesi Presensi Aktif',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.badgeGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.badgeGreen),
            ),
            child: const Row(
              children: [
                Icon(Icons.sensors_rounded, color: AppColors.badgeGreen, size: 16),
                SizedBox(width: 6),
                Text(
                  'REALTIME RADAR',
                  style: TextStyle(color: AppColors.badgeGreen, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          final panels = <Widget>[
            Expanded(
              flex: 5,
              child: _buildQrPanel(isWide: isWide, maxWidth: constraints.maxWidth),
            ),
            isWide
                ? Container(width: 1, color: const Color(0xFF1E293B))
                : Container(height: 1, color: const Color(0xFF1E293B)),
            Expanded(flex: 4, child: _buildAttendeePanel()),
          ];

          // Landscape/tablet: kiri-kanan. Portrait: atas-bawah.
          return isWide
              ? Row(children: panels)
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: panels,
          );
        },
      ),
    );
  }

  // ================
  // PANEL QR DINAMIS
  // ================
  Widget _buildQrPanel({required bool isWide, required double maxWidth}) {
    // Landscape: tetap 260. Portrait: menyesuaikan lebar layar (160-220).
    final qrSize = isWide ? 260.0 : (maxWidth - 92).clamp(160.0, 220.0).toDouble();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _currentQrPayload.isEmpty
                  ? SizedBox(
                width: qrSize,
                height: qrSize,
                child: const Center(child: CircularProgressIndicator()),
              )
                  : QrImageView(
                data: _currentQrPayload,
                version: QrVersions.auto,
                size: qrSize,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Indikator Siklus Refresh Token
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: _secondsLeft / 20.0,
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    backgroundColor: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Token berganti dalam $_secondsLeft detik',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan mahasiswa berada di dalam radius ruang kelas (≤ 50 meter)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANEL DAFTAR KEHADIRAN REALTIME
  // ==========================================
  Widget _buildAttendeePanel() {
    return Container(
      color: const Color(0xFF131D31),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Daftar Kehadiran Masuk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_attendees.length} Mahasiswa',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingInitialData
                ? const Center(child: CircularProgressIndicator())
                : _attendees.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 48, color: Color(0xFF475569)),
                  SizedBox(height: 10),
                  Text(
                    'Menunggu mahasiswa memindai QR...',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            )
                : ListView.separated(
              itemCount: _attendees.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _attendees[index];
                final profile = item['profiles'] as Map<String, dynamic>?;
                final name = profile?['name'] ?? 'Mahasiswa';
                final nim = profile?['identifier_id'] ?? '-';
                final dist = item['verified_distance'] != null
                    ? '${(item['verified_distance'] as num).toStringAsFixed(1)}m'
                    : 'Terverifikasi';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.badgeGreen.withValues(alpha: 0.15),
                        child: const Icon(Icons.check_rounded, color: AppColors.badgeGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'NIM: $nim',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dist,
                          style: const TextStyle(
                            color: AppColors.badgeGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
  }
}