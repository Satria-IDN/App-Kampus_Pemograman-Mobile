import 'package:geolocator/geolocator.dart';

class GeofenceResult {
  final bool isWithinRange;
  final double distanceInMeters;
  final double accuracy;
  final bool isMocked;
  final String? errorMessage;

  GeofenceResult({
    required this.isWithinRange,
    required this.distanceInMeters,
    required this.accuracy,
    required this.isMocked,
    this.errorMessage,
  });
}

class GeofenceService {
  /// Memeriksa status izin lokasi perangkat
  static Future<String?> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Layanan lokasi/GPS pada perangkat Anda belum diaktifkan.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Izin akses lokasi ditolak oleh pengguna.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Izin lokasi diblokir permanen. Aktifkan manual melalui Pengaturan Aplikasi.';
    }

    return null; // Izin aman
  }

  static Future<Position> getCurrentPosition() async {
    final permissionError = await checkAndRequestPermission();
    if (permissionError != null) {
      throw permissionError;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (position.isMocked) {
        throw 'Terdeteksi aplikasi lokasi palsu (Mock GPS)! Harap matikan Fake GPS.';
      }

      return position;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Gagal mengunci sinyal GPS. Pastikan berada di area dengan sinyal GPS baik.';
    }
  }

  /// Memvalidasi posisi pengguna terhadap titik koordinat target ruangan
  static Future<GeofenceResult> validateUserLocation({
    required double targetLat,
    required double targetLng,
    required double radiusInMeters,
    double bufferTolerance = 0.0, // PRD: radius maksimal 50 m, tanpa buffer tambahan
  }) async {
    // 1. Cek izin
    final permissionError = await checkAndRequestPermission();
    if (permissionError != null) {
      return GeofenceResult(
        isWithinRange: false,
        distanceInMeters: -1,
        accuracy: -1,
        isMocked: false,
        errorMessage: permissionError,
      );
    }

    // 2. Ambil koordinat GPS akurasi tinggi
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return GeofenceResult(
        isWithinRange: false,
        distanceInMeters: -1,
        accuracy: -1,
        isMocked: false,
        errorMessage: 'Gagal mengunci sinyal GPS. Coba di dekat jendela atau ruang terbuka.',
      );
    }

    // 3. Deteksi Fake GPS / Mock Location
    if (position.isMocked) {
      return GeofenceResult(
        isWithinRange: false,
        distanceInMeters: -1,
        accuracy: position.accuracy,
        isMocked: true,
        errorMessage: 'Terdeteksi aplikasi lokasi palsu (Mock GPS). Presensi dibatalkan!',
      );
    }

    // 4. Hitung jarak riil (Metode Haversine)
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLng,
    );

    // 5. Evaluasi batas radius + buffer toleransi
    final allowedRadius = radiusInMeters + bufferTolerance;
    final isInside = distance <= allowedRadius;

    return GeofenceResult(
      isWithinRange: isInside,
      distanceInMeters: distance,
      accuracy: position.accuracy,
      isMocked: false,
      errorMessage: isInside
          ? null
          : 'Di luar radius kelas. Jarak Anda: ${distance.toStringAsFixed(1)}m (Batas: ${radiusInMeters.toInt()}m)',
    );
  }
}