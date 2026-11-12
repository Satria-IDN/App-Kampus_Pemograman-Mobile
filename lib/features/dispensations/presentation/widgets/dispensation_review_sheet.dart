import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dispensation_entity.dart';

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_shortMonths[d.month - 1]} ${d.year}';

/// Daftar pengajuan dispensasi yang menunggu keputusan dosen.
class DispensationReviewSheet extends StatefulWidget {
  final List<DispensationEntity> items;
  final Future<void> Function(String id, bool approve, String? note) onReview;
  final Future<String?> Function(String path) getDocumentUrl;

  const DispensationReviewSheet({
    super.key,
    required this.items,
    required this.onReview,
    required this.getDocumentUrl,
  });

  @override
  State<DispensationReviewSheet> createState() => _DispensationReviewSheetState();
}

class _DispensationReviewSheetState extends State<DispensationReviewSheet> {
  late final List<DispensationEntity> _items = List.of(widget.items);
  final Map<String, TextEditingController> _notes = {};
  String? _busyId;
  String? _error;

  TextEditingController _noteFor(String id) =>
      _notes.putIfAbsent(id, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _review(DispensationEntity item, bool approve) async {
    setState(() {
      _busyId = item.id;
      _error = null;
    });
    try {
      await widget.onReview(item.id, approve, _noteFor(item.id).text);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((e) => e.id == item.id);
        _busyId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _error = '$e';
      });
    }
  }

  Future<void> _showDocument(String path) async {
    final url = await widget.getDocumentUrl(path);
    if (!mounted) return;
    if (url == null) {
      setState(() => _error = 'Lampiran tidak dapat dibuka.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
            errorBuilder: (context, error, stack) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Gagal memuat gambar lampiran.'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Verifikasi Dispensasi (${_items.length})',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.badgeRed)),
              ),
            Flexible(
              child: _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada pengajuan yang menunggu keputusan.',
                        style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildItem(_items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(DispensationEntity d) {
    final busy = _busyId == d.id;
    final docPath = d.documentPath;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  d.studentName ?? 'Mahasiswa',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: d.type == 'sakit' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  d.typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: d.type == 'sakit' ? AppColors.badgeRed : AppColors.badgeOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'NIM ${d.studentNim ?? '-'} • ${d.courseCode} ${d.courseName}',
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
          const SizedBox(height: 2),
          Text(
            'Tidak hadir: ${_formatDate(d.absenceDate)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
          const SizedBox(height: 8),
          Text(d.reason, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
          if (docPath != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              onPressed: () => _showDocument(docPath),
              icon: const Icon(Icons.image_search_rounded, size: 16),
              label: const Text('Lihat lampiran', style: TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _noteFor(d.id),
            decoration: InputDecoration(
              hintText: 'Catatan untuk mahasiswa (opsional)',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.badgeRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: busy ? null : () => _review(d, false),
                  child: const Text('Tolak', style: TextStyle(color: AppColors.badgeRed)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.badgeGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: busy ? null : () => _review(d, true),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Setujui', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
