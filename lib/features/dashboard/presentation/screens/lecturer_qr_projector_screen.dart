import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/qr_token_service.dart';
import '../../../../core/theme/app_colors.dart';

class LecturerQrProjectorScreen extends StatefulWidget {
  final String sessionId;
  final String courseName;
  final String roomName;

  const LecturerQrProjectorScreen({
    super.key,
    required this.sessionId,
    required this.courseName,
    required this.roomName,
  });

  @override
  State<LecturerQrProjectorScreen> createState() => _LecturerQrProjectorScreenState();
}

class _LecturerQrProjectorScreenState extends State<LecturerQrProjectorScreen> {
  Timer? _timer;
  late String _currentPayload;
  int _secondsLeft = 20;

  @override
  void initState() {
    super.initState();
    // 1. Kunci layar ke mode Fullscreen Landscape untuk proyektor
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _refreshQr();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _refreshQr();
      }
    });
  }

  void _refreshQr() {
    setState(() {
      _secondsLeft = 20;
      _currentPayload = QrTokenService.generateSessionPayload(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 2. Kembalikan layar ke orientasi potret normal saat keluar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Panel Kiri: Informasi Sesi & Countdown Bar
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF065F46),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'MODE PROYEKTOR AKTIF',
                        style: TextStyle(color: AppColors.badgeGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.courseName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ruangan: ${widget.roomName}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _secondsLeft / 20.0,
                        minHeight: 10,
                        backgroundColor: Colors.white12,
                        color: _secondsLeft <= 5 ? AppColors.badgeRed : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR diperbarui otomatis dalam $_secondsLeft detik',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.badgeRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      label: const Text('Tutup Layar Proyektor', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Panel Kanan: Dynamic QR Ukuran Besar
              Expanded(
                flex: 5,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _currentPayload,
                      version: QrVersions.auto,
                      size: 260.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}