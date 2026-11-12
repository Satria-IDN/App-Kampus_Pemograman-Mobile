/// Kategori sesi perkuliahan (PRD FR-03): reguler, workshop, kuliah tamu.
class SessionTypes {
  static const Map<String, String> filters = {
    'semua': 'Semua',
    'reguler': 'Reguler',
    'workshop': 'Workshop',
    'kuliah_tamu': 'Kuliah Tamu',
  };

  /// Menyamakan nilai lama ('Reguler', 'Tamu') dengan nilai PRD.
  static String normalize(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'workshop':
        return 'workshop';
      case 'kuliah_tamu':
      case 'tamu':
        return 'kuliah_tamu';
      default:
        return 'reguler';
    }
  }

  static String label(String type) {
    switch (type) {
      case 'workshop':
        return 'Workshop';
      case 'kuliah_tamu':
        return 'Kuliah Tamu';
      default:
        return 'Reguler';
    }
  }
}
