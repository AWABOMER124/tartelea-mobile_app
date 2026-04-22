import 'package:flutter/material.dart';

import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';

class AppSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const AppSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  }) : assert(labels.length >= 2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        (isDark ? AppColors.darkPrimary : AppColors.accent).withAlpha(32);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: i == index,
                selectedColor: selectedColor,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.chip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s12,
            horizontal: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: AppRadius.chip,
            border: selected
                ? Border.all(
                    color: (isDark ? AppColors.darkPrimary : AppColors.accent)
                        .withAlpha(120),
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.textPrimary(isDark)
                      : AppColors.textSecondary(isDark),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

