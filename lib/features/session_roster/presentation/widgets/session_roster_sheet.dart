import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/session_roster.dart';

/// Daftar kehadiran satu sesi: tidak hadir, izin/sakit, dan hadir.
class SessionRosterSheet extends StatefulWidget {
  final String title;
  final Future<SessionRoster> Function() load;

  const SessionRosterSheet({super.key, required this.title, required this.load});

  @override
  State<SessionRosterSheet> createState() => _SessionRosterSheetState();
}

class _SessionRosterSheetState extends State<SessionRosterSheet> {
  SessionRoster? _roster;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _roster = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _time(DateTime? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final r = _roster;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
                IconButton(
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textGrey),
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Gagal memuat daftar kehadiran.\n$_error',
                style: const TextStyle(fontSize: 12, color: AppColors.badgeRed),
              ),
            )
          else if (r != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _summaryChip('Hadir ${r.presentCount}', AppColors.badgeGreen),
                  _summaryChip('Izin/Sakit ${r.excusedCount}', AppColors.badgeOrange),
                  _summaryChip(
                    r.isActive ? 'Belum hadir ${r.absentCount}' : 'Alpa ${r.absentCount}',
                    AppColors.badgeRed,
                  ),
                ],
              ),
            ),
            Flexible(
              child: r.entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada peserta terdaftar (KRS) maupun yang hadir pada sesi ini.',
                        style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: r.entries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _buildTile(r.entries[i], r.isActive),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildTile(RosterEntry e, bool sessionActive) {
    Color color;
    String label;
    if (e.isPresent) {
      color = AppColors.badgeGreen;
      label = 'Hadir';
    } else if (e.status == 'izin') {
      color = AppColors.badgeOrange;
      label = 'Izin';
    } else if (e.status == 'sakit') {
      color = AppColors.badgeOrange;
      label = 'Sakit';
    } else if (e.status == 'belum') {
      color = AppColors.badgeRed;
      label = 'Belum hadir';
    } else {
      color = AppColors.badgeRed;
      label = 'Alpa';
    }

    final parts = <String>['NIM ${e.nim}'];
    if (e.isPresent && e.scannedAt != null) parts.add('pukul ${_time(e.scannedAt)}');
    if (!e.enrolled) parts.add('bukan peserta KRS');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  parts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
