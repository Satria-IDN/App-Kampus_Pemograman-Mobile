import 'package:flutter/material.dart';
import '../constants/session_types.dart';
import '../theme/app_colors.dart';

/// Baris chip filter kategori sesi (Semua / Reguler / Workshop / Kuliah Tamu).
class SessionTypeFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const SessionTypeFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: SessionTypes.filters.entries.map((e) {
        final isSelected = selected == e.key;
        return ChoiceChip(
          label: Text(
            e.value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textGrey,
            ),
          ),
          selected: isSelected,
          showCheckmark: false,
          selectedColor: AppColors.primary,
          backgroundColor: const Color(0xFFF1F5F9),
          onSelected: (_) => onChanged(e.key),
        );
      }).toList(),
    );
  }
}
