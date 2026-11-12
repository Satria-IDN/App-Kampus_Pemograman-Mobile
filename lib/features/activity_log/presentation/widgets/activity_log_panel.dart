import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/activity_log_repository_impl.dart';
import '../../domain/entities/activity_event.dart';
import '../../domain/usecases/get_recent_activity.dart';

/// Log aktivitas sistem: sesi dibuka/ditutup dan ruangan ditambahkan.
class ActivityLogPanel extends StatefulWidget {
  const ActivityLogPanel({super.key});

  @override
  State<ActivityLogPanel> createState() => _ActivityLogPanelState();
}

class _ActivityLogPanelState extends State<ActivityLogPanel> {
  final GetRecentActivity _getRecent = GetRecentActivity(ActivityLogRepositoryImpl());

  List<ActivityEvent> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _getRecent();
      if (!mounted) return;
      setState(() {
        _events = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  static const List<String> _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _format(DateTime? t) {
    if (t == null) return '-';
    final dd = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$dd ${_shortMonths[t.month - 1]} ${t.year} • $hh:$mm WIB';
  }

  Color _colorFor(ActivityKind kind) {
    switch (kind) {
      case ActivityKind.sessionOpened:
        return AppColors.primary;
      case ActivityKind.sessionClosed:
        return AppColors.badgeGreen;
      case ActivityKind.roomAdded:
        return AppColors.badgeOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = [];

    if (_isLoading) {
      body.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else if (_error != null) {
      body.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Text(
          'Gagal memuat log aktivitas.\n$_error',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.badgeRed),
        ),
      ));
    } else if (_events.isEmpty) {
      body.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: const Text(
          'Belum ada aktivitas tercatat.',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ));
    } else {
      for (final e in _events) {
        body.add(_buildTile(e));
        body.add(const SizedBox(height: 10));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Catatan sesi presensi dan perubahan ruangan',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _isLoading ? null : _load,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...body,
      ],
    );
  }

  Widget _buildTile(ActivityEvent e) {
    final color = _colorFor(e.kind);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(e.detail, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                Text(_format(e.time), style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
