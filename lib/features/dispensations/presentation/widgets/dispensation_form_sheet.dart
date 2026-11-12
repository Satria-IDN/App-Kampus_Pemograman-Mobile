import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dispensation_entity.dart';

class DispensationCourseOption {
  final String id;
  final String label;
  const DispensationCourseOption({required this.id, required this.label});
}

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_shortMonths[d.month - 1]} ${d.year}';

/// Form pengajuan izin / sakit oleh mahasiswa (dengan lampiran foto opsional).
class DispensationFormSheet extends StatefulWidget {
  final String studentId;
  final List<DispensationCourseOption> courses;
  final Future<void> Function(NewDispensation input) onSubmit;

  const DispensationFormSheet({
    super.key,
    required this.studentId,
    required this.courses,
    required this.onSubmit,
  });

  @override
  State<DispensationFormSheet> createState() => _DispensationFormSheetState();
}

class _DispensationFormSheetState extends State<DispensationFormSheet> {
  late final TextEditingController _reasonCtrl;

  String? _courseId;
  late DateTime _date;
  String _type = 'izin';
  Uint8List? _docBytes;
  String? _docName;
  String? _docExt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    if (widget.courses.length == 1) _courseId = widget.courses.first.id;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(const Duration(days: 30)),
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickDocument() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _docBytes = bytes;
        _docName = picked.name;
        _docExt = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memilih berkas: $e');
    }
  }

  Future<void> _submit() async {
    if (_courseId == null) {
      setState(() => _error = 'Pilih mata kuliah.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        NewDispensation(
          studentId: widget.studentId,
          courseId: _courseId!,
          absenceDate: _date,
          type: _type,
          reason: _reasonCtrl.text,
          documentBytes: _docBytes,
          documentExtension: _docExt,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajukan Izin / Sakit',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pengajuan akan dikirim ke dosen pengampu. Jika disetujui, pertemuan pada tanggal tersebut tidak dihitung alpa.',
              style: TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: _decoration('Mata kuliah'),
              items: widget.courses
                  .map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _courseId = v),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text('Tanggal tidak hadir: ${_formatDate(_date)}'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Izin'),
                  selected: _type == 'izin',
                  onSelected: (_) => setState(() => _type = 'izin'),
                ),
                ChoiceChip(
                  label: const Text('Sakit'),
                  selected: _type == 'sakit',
                  onSelected: (_) => setState(() => _type = 'sakit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: _decoration('Alasan', hint: 'Contoh: demam, surat dokter terlampir'),
            ),
            const SizedBox(height: 10),
            if (_docBytes == null)
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickDocument,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text('Lampirkan foto surat (opsional)'),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_rounded, color: AppColors.badgeGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _docName ?? 'Lampiran',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.badgeRed),
                      onPressed: () => setState(() {
                        _docBytes = null;
                        _docName = null;
                        _docExt = null;
                      }),
                    ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.badgeRed)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Kirim Pengajuan',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
