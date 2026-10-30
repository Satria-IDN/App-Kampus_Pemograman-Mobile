import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrTokenService {
  /// Masa berlaku satu blok token (PRD: rotasi 30 detik).
  static const int tokenTtlSeconds = 30;
  static const String secretKey = "KUNCI_RAHASIA_KAMPUS_PULSE_2026";

  /// Nomor blok waktu saat ini.
  static int currentBlock() =>
      DateTime.now().millisecondsSinceEpoch ~/ (tokenTtlSeconds * 1000);

  /// Sisa detik sampai blok berganti (1..tokenTtlSeconds), selaras dengan blok token.
  static int secondsRemaining() {
    final elapsed = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % tokenTtlSeconds;
    return tokenTtlSeconds - elapsed;
  }

  /// Dosen: Menghasilkan payload QR dinamis berbasis waktu
  static String generateSessionPayload(String sessionId) {
    final timeBlock = currentBlock();

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

      final nowBlock = currentBlock();

      // Grace period: blok sekarang atau 1 blok sebelumnya (T-1)
      if (scannedBlock != nowBlock && scannedBlock != (nowBlock - 1)) {
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
