import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrTokenService {
  static const int tokenTtlSeconds = 20;
  static const String secretKey = "KUNCI_RAHASIA_KAMPUS_PULSE_2026";

  /// Dosen: Menghasilkan payload QR dinamis berbasis waktu
  static String generateSessionPayload(String sessionId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeBlock = now ~/ (tokenTtlSeconds * 1000);

    final rawString = '$sessionId-$timeBlock-$secretKey';
    final token = sha256.convert(utf8.encode(rawString)).toString().substring(0, 8);

    return jsonEncode({
      'session_id': sessionId,
      'time_block': timeBlock,
      'token': token,
    });
  }

  /// Mahasiswa: Memvalidasi apakah token QR masih aktif saat dipindai
  static bool validateToken(String rawPayload) {
    try {
      final data = jsonDecode(rawPayload);
      final sessionId = data['session_id'];
      final scannedBlock = data['time_block'] as int;
      final scannedToken = data['token'];

      final currentBlock = DateTime.now().millisecondsSinceEpoch ~/ (tokenTtlSeconds * 1000);

      // Toleransi 1 interval waktu sebelumnya untuk antisipasi jeda render
      if (scannedBlock != currentBlock && scannedBlock != (currentBlock - 1)) {
        return false;
      }

      final expectedRaw = '$sessionId-$scannedBlock-$secretKey';
      final expectedToken = sha256.convert(utf8.encode(expectedRaw)).toString().substring(0, 8);

      return scannedToken == expectedToken;
    } catch (_) {
      return false;
    }
  }
}